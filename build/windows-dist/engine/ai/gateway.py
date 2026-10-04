"""
AI Gateway — provider-agnostic interface for all AI operations.
Supports: OpenAI-compatible APIs, Gemini, Anthropic, Ollama, LM Studio.
Falls back to deterministic rules if all providers fail (ADR-008).
"""

from __future__ import annotations

import hashlib
import json
import time
from typing import Any, Optional
from dataclasses import dataclass, field

import httpx
import structlog
from pydantic import BaseModel, Field, field_validator

from collection.safe_http import SafeHTTPClient

log = structlog.get_logger(__name__)

# ── Cache ─────────────────────────────────────────────────────────────────────
# Simple in-memory cache: key -> (result, expiry_timestamp)
_cache: dict[str, tuple[Any, float]] = {}
_CACHE_TTL_SECONDS = 7 * 24 * 3600  # 7 days


def _cache_key(*parts: str) -> str:
    return hashlib.sha256("|".join(parts).encode()).hexdigest()


def _cache_get(key: str) -> Optional[Any]:
    entry = _cache.get(key)
    if entry and time.time() < entry[1]:
        return entry[0]
    return None


def _cache_set(key: str, value: Any) -> None:
    _cache[key] = (value, time.time() + _CACHE_TTL_SECONDS)


# ── Pydantic output schemas ───────────────────────────────────────────────────

class SearchFiltersExtracted(BaseModel):
    """Interpreted search filters from natural language query."""
    keywords: list[str] = Field(default_factory=list)
    categories: list[str] = Field(default_factory=list)
    countries: list[str] = Field(default_factory=list)
    languages: list[str] = Field(default_factory=list)
    deadline_before: Optional[str] = None
    amount_min: Optional[int] = None
    amount_max: Optional[int] = None
    remote_only: bool = False
    confidence: float = Field(default=0.7, ge=0.0, le=1.0)


class OpportunityExtraction(BaseModel):
    """Structured extraction result from raw HTML/text content."""
    title: Optional[str] = None
    organization: Optional[str] = None
    category: Optional[str] = None
    deadline: Optional[str] = None      # ISO 8601 date if found
    location: Optional[str] = None
    amount_min: Optional[int] = None
    amount_max: Optional[int] = None
    currency_code: Optional[str] = None
    language: Optional[str] = None
    eligibility_text: Optional[str] = None
    summary: Optional[str] = None       # ≤ 5 lines
    required_skills: list[str] = Field(default_factory=list)
    required_languages: list[str] = Field(default_factory=list)
    min_education_level: Optional[str] = None
    min_experience_years: Optional[float] = None
    extraction_confidence: float = Field(default=0.5, ge=0.0, le=1.0)


# ── Provider configuration ────────────────────────────────────────────────────

@dataclass
class ProviderConfig:
    name: str
    provider_type: str    # openai_compat | gemini | anthropic | ollama | lmstudio
    model: str
    api_key: Optional[str]
    base_url: str
    is_local: bool = False
    max_tokens: int = 2000
    temperature: float = 0.1   # Low temperature for extraction tasks


# ── AIGateway ─────────────────────────────────────────────────────────────────

class AIGateway:
    """
    Provider-agnostic AI gateway.
    All operations have a deterministic fallback path.
    """

    def __init__(self, providers: list[ProviderConfig]) -> None:
        self._providers = providers
        # Local AI providers (Ollama/LMStudio) get an unchecked HTTP client
        self._local_client = httpx.AsyncClient(timeout=60.0)
        # Remote providers use the SSRF-safe client
        self._remote_client = SafeHTTPClient()

    async def interpret_query(
        self, query: str, profile_summary: Optional[dict] = None
    ) -> SearchFiltersExtracted:
        """
        Interpret a natural language search query into structured filters.
        Example: "bourses master droit francophone Cameroun 2025"
        → {categories: ['bourse'], countries: ['CM'], languages: ['fr'], ...}
        """
        cache_k = _cache_key("interpret", query)
        if cached := _cache_get(cache_k):
            return SearchFiltersExtracted(**cached)

        system = """Tu es un assistant d'extraction de filtres de recherche pour une plateforme d'opportunités africaines.
Extrais des filtres structurés à partir de la requête utilisateur.
IMPORTANT: N'inclus PAS de données personnelles dans ta réponse. Réponds UNIQUEMENT en JSON valide."""

        user_prompt = f"""REQUÊTE: {query[:500]}

Extrais les filtres suivants si présents:
- keywords: mots-clés principaux (liste de strings)
- categories: catégories parmi: bourse, emploi, appel_offres, subvention, entrepreneuriat, recherche, volontariat, formation
- countries: codes ISO 3166-1 alpha-2 (ex: CM, SN, CD, GA, CI)
- languages: codes ISO 639-1 (ex: fr, en)
- deadline_before: date limite au format YYYY-MM-DD si mentionnée
- amount_min et amount_max: montants en XAF si mentionnés
- remote_only: true si l'utilisateur cherche uniquement du télétravail

Réponds UNIQUEMENT avec le JSON, sans texte supplémentaire."""

        result = await self._call_with_fallback(
            system_prompt=system,
            user_prompt=user_prompt,
            output_schema=SearchFiltersExtracted,
            fallback_fn=lambda: self._interpret_query_fallback(query),
        )
        _cache_set(cache_k, result.model_dump())
        return result

    async def extract_opportunity(
        self, content: str, source_url: str, existing_title: Optional[str] = None
    ) -> OpportunityExtraction:
        """
        Extract structured opportunity data from raw content.
        Content MUST be sanitized text (no scripts, no raw HTML).
        """
        content_hash = hashlib.sha256(content[:5000].encode()).hexdigest()
        cache_k = _cache_key("extract", source_url, content_hash)
        if cached := _cache_get(cache_k):
            return OpportunityExtraction(**cached)

        system = """Tu es un extracteur de données structurées pour des opportunités (bourses, emplois, appels d'offres, subventions).
Extrais avec précision. Ne génère PAS d'informations non présentes dans le texte.
Marque ta confiance dans extraction_confidence (0.0-1.0).
Réponds UNIQUEMENT en JSON valide."""

        # Prevent prompt injection: data is in a delimited block
        user_prompt = f"""Extrais les données structurées de l'opportunité ci-dessous.

URL SOURCE: {source_url[:200]}
{'TITRE CONNU: ' + existing_title[:200] if existing_title else ''}

===DÉBUT DU CONTENU===
{content[:6000]}
===FIN DU CONTENU===

Extrais: title, organization, category, deadline (ISO 8601), location, amount_min, amount_max, currency_code, language (ISO 639-1), eligibility_text (verbatim), summary (≤5 lignes), required_skills, required_languages, min_education_level, min_experience_years, extraction_confidence."""

        result = await self._call_with_fallback(
            system_prompt=system,
            user_prompt=user_prompt,
            output_schema=OpportunityExtraction,
            fallback_fn=lambda: OpportunityExtraction(
                title=existing_title,
                extraction_confidence=0.0,
            ),
        )
        _cache_set(cache_k, result.model_dump())
        return result

    async def summarize(self, text: str, max_lines: int = 5) -> str:
        """Generate a concise summary of opportunity text."""
        if not text:
            return ""

        cache_k = _cache_key("summarize", hashlib.sha256(text[:3000].encode()).hexdigest())
        if cached := _cache_get(cache_k):
            return cached

        system = f"Tu résumes des opportunités en français en maximum {max_lines} lignes courtes. Sois factuel et concis."
        user_prompt = f"===DÉBUT DU TEXTE===\n{text[:4000]}\n===FIN DU TEXTE===\n\nRésumé en {max_lines} lignes:"

        result = await self._call_provider_text(system, user_prompt, max_tokens=500)
        _cache_set(cache_k, result)
        return result

    async def explain_match(
        self, opportunity_summary: str, profile_summary: str, score_data: dict
    ) -> str:
        """
        Generate a human-readable explanation of a match score.
        Profile data is anonymized before sending (name/email/phone removed).
        """
        system = "Tu expliques en français pourquoi un profil correspond ou non à une opportunité. Sois direct et constructif."

        user_prompt = f"""SCORE: {score_data.get('total_score', 0)}/100 — Éligibilité: {score_data.get('eligibility', 'uncertain')}

OPPORTUNITÉ: {opportunity_summary[:500]}

PROFIL (anonymisé): {profile_summary[:500]}

Points forts identifiés: {', '.join(score_data.get('strengths', [])[:3])}
Points faibles identifiés: {', '.join(score_data.get('gaps', [])[:3])}

Explique en 3-4 phrases pourquoi ce profil obtient ce score pour cette opportunité."""

        return await self._call_provider_text(system, user_prompt, max_tokens=400)

    async def generate_document(
        self,
        doc_type: str,
        opportunity_data: dict,
        profile_data: dict,
    ) -> str:
        """
        Generate a document draft (cover letter, grant proposal outline).
        Profile must be reviewed/approved by user before sending.
        """
        type_names = {
            "cover_letter": "lettre de motivation",
            "grant_proposal": "proposition de subvention",
            "application_summary": "résumé de candidature",
        }
        type_name = type_names.get(doc_type, doc_type)

        system = f"""Tu rédiges une ébauche de {type_name} en français pour une opportunité africaine.
L'ébauche DOIT être révisée et personnalisée par l'utilisateur avant envoi.
Commence par un avertissement clair: "[ÉBAUCHE IA — À RÉVISER AVANT ENVOI]" """

        user_prompt = f"""OPPORTUNITÉ: {opportunity_data.get('title', 'N/A')} — {opportunity_data.get('organization', 'N/A')}

PROFIL (anonymisé): statut={profile_data.get('status', 'N/A')}, formation={profile_data.get('education_level', 'N/A')}, exp={profile_data.get('experience_years', 0)} ans

Rédige une ébauche de {type_name} d'environ 300 mots."""

        return await self._call_provider_text(system, user_prompt, max_tokens=800)

    # ── Internal provider calls ───────────────────────────────────────────────

    async def _call_with_fallback(
        self,
        system_prompt: str,
        user_prompt: str,
        output_schema: type[BaseModel],
        fallback_fn,
    ) -> BaseModel:
        """Try providers in order; fall back to deterministic function."""
        for provider in self._providers:
            try:
                text = await self._call_provider(provider, system_prompt, user_prompt)
                # Extract JSON from response
                json_text = self._extract_json(text)
                data = json.loads(json_text)
                return output_schema(**data)
            except Exception as e:
                log.warning("ai_provider_failed", provider=provider.name, error=str(e))
                continue

        # All providers failed — use deterministic fallback
        log.info("ai_using_fallback")
        return fallback_fn()

    async def _call_provider_text(
        self, system_prompt: str, user_prompt: str, max_tokens: int = 500
    ) -> str:
        """Call providers for plain text response."""
        for provider in self._providers:
            try:
                return await self._call_provider(
                    provider, system_prompt, user_prompt, max_tokens=max_tokens
                )
            except Exception as e:
                log.warning("ai_text_provider_failed", provider=provider.name, error=str(e))
        return ""

    async def _call_provider(
        self,
        provider: ProviderConfig,
        system_prompt: str,
        user_prompt: str,
        max_tokens: Optional[int] = None,
    ) -> str:
        """Make API call to a specific provider."""
        max_tokens = max_tokens or provider.max_tokens

        if provider.provider_type in ("openai_compat", "ollama", "lmstudio"):
            return await self._call_openai_compat(provider, system_prompt, user_prompt, max_tokens)
        elif provider.provider_type == "gemini":
            return await self._call_gemini(provider, system_prompt, user_prompt, max_tokens)
        elif provider.provider_type == "anthropic":
            return await self._call_anthropic(provider, system_prompt, user_prompt, max_tokens)
        else:
            raise ValueError(f"Unknown provider type: {provider.provider_type}")

    async def _call_openai_compat(
        self, provider: ProviderConfig, system: str, user: str, max_tokens: int
    ) -> str:
        client = self._local_client if provider.is_local else self._remote_client
        headers = {"Content-Type": "application/json"}
        if provider.api_key:
            headers["Authorization"] = f"Bearer {provider.api_key}"

        body = {
            "model": provider.model,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
            "max_tokens": max_tokens,
            "temperature": provider.temperature,
        }

        if provider.is_local:
            resp = await client.post(
                f"{provider.base_url}/chat/completions",
                json=body, headers=headers, timeout=60.0,
            )
        else:
            resp = await client.post(
                f"{provider.base_url}/chat/completions",
                json=body, headers=headers,
            )
        resp.raise_for_status()
        data = resp.json()
        return data["choices"][0]["message"]["content"]

    async def _call_gemini(
        self, provider: ProviderConfig, system: str, user: str, max_tokens: int
    ) -> str:
        url = f"{provider.base_url}/models/{provider.model}:generateContent?key={provider.api_key}"
        body = {
            "contents": [{"parts": [{"text": f"{system}\n\n{user}"}]}],
            "generationConfig": {
                "temperature": provider.temperature,
                "maxOutputTokens": max_tokens,
            },
        }
        resp = await self._remote_client.post(url, json=body)
        resp.raise_for_status()
        data = resp.json()
        return data["candidates"][0]["content"]["parts"][0]["text"]

    async def _call_anthropic(
        self, provider: ProviderConfig, system: str, user: str, max_tokens: int
    ) -> str:
        headers = {
            "x-api-key": provider.api_key or "",
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        }
        body = {
            "model": provider.model,
            "max_tokens": max_tokens,
            "system": system,
            "messages": [{"role": "user", "content": user}],
        }
        resp = await self._remote_client.post(
            f"{provider.base_url}/messages", json=body, headers=headers,
        )
        resp.raise_for_status()
        data = resp.json()
        return data["content"][0]["text"]

    @staticmethod
    def _extract_json(text: str) -> str:
        """Extract JSON from a model response that may have extra text."""
        # Try to find JSON block
        import re
        # Look for ```json ... ``` blocks
        match = re.search(r"```json\s*(.*?)\s*```", text, re.DOTALL)
        if match:
            return match.group(1)
        # Look for raw { ... } block
        start = text.find("{")
        end = text.rfind("}")
        if start != -1 and end != -1:
            return text[start:end + 1]
        return text

    def _interpret_query_fallback(self, query: str) -> SearchFiltersExtracted:
        """
        Deterministic query interpretation without AI.
        Uses keyword matching for categories and country names.
        """
        q = query.lower()
        categories = []
        countries = []
        keywords = [w for w in q.split() if len(w) > 3]

        # Category detection
        if any(w in q for w in ["bourse", "scholarship", "fellowship", "grant étudiant"]):
            categories.append("bourse")
        if any(w in q for w in ["emploi", "job", "poste", "recrutement", "vacancy"]):
            categories.append("emploi")
        if any(w in q for w in ["appel d'offres", "appel offres", "procurement", "tender"]):
            categories.append("appel_offres")
        if any(w in q for w in ["subvention", "financement", "grant", "fonds"]):
            categories.append("subvention")
        if any(w in q for w in ["entrepreneur", "startup", "sme", "pme"]):
            categories.append("entrepreneuriat")

        # Country detection
        country_map = {
            "cameroun": "CM", "cameroon": "CM",
            "sénégal": "SN", "senegal": "SN",
            "côte d'ivoire": "CI", "cote ivoire": "CI",
            "gabon": "GA", "congo": "CG", "rdc": "CD", "mali": "ML",
            "burkina": "BF", "togo": "TG", "bénin": "BJ", "niger": "NE",
        }
        for name, code in country_map.items():
            if name in q:
                countries.append(code)

        return SearchFiltersExtracted(
            keywords=keywords[:10],
            categories=categories or [],
            countries=countries,
            confidence=0.4,   # Low confidence since no AI was used
        )
