"""Rule-based natural-language query interpretation, FR/EN (EF-04.01..04).

"bourse de master en France pour 2027 en anglais" →
{categories: [scholarship.master], countries: [FR], languages: [en], keywords: [...], ...}

The output is shown to the user as editable filters before the search starts (EF-04.03).
"""

from __future__ import annotations

import re
from datetime import date
from typing import Any

from core.text import fold, fold_words

CATEGORY_TERMS: dict[str, tuple[str, ...]] = {
    "scholarship.master": ("bourse de master", "master scholarship", "masters scholarship", "bourse master"),
    "scholarship.phd": (
        "bourse de doctorat",
        "bourse de these",
        "phd scholarship",
        "doctoral scholarship",
        "phd funding",
    ),
    "scholarship.bachelor": ("bourse de licence", "undergraduate scholarship", "bachelor scholarship"),
    "scholarship": (
        "bourse",
        "bourses",
        "scholarship",
        "scholarships",
        "fellowship",
        "fellowships",
        "etudier a l'etranger",
        "study abroad",
    ),
    "grant.startup": ("financement startup", "startup funding", "seed funding", "financement de startup"),
    "grant.association": (
        "financement associatif",
        "subvention association",
        "subvention pour ong",
        "ngo grant",
        "grants for ngos",
    ),
    "grant.research": ("financement de recherche", "research grant", "research funding"),
    "grant": (
        "subvention",
        "subventions",
        "grant",
        "grants",
        "financement",
        "funding",
        "appel a projets",
        "call for proposals",
    ),
    "tender.it_services": ("appel d'offres informatique", "it tender", "marche informatique", "software tender"),
    "tender": (
        "appel d'offres",
        "appels d'offres",
        "marche public",
        "marches publics",
        "tender",
        "tenders",
        "procurement",
        "rfp",
        "consultation",
    ),
    "internship": ("stage", "stages", "internship", "internships", "stagiaire"),
    "employment.consultancy": ("consultance", "consultancy", "consultant"),
    "employment": (
        "emploi",
        "emplois",
        "job",
        "jobs",
        "poste",
        "offre d'emploi",
        "travail",
        "recrutement",
        "vacancy",
        "vacancies",
    ),
    "freelance": ("freelance", "mission freelance", "independant"),
    "competition": ("concours", "competition", "prix", "prize", "award", "hackathon", "challenge"),
    "training": ("formation", "formations", "training", "cours", "course", "certification", "mooc"),
    "acceleration": ("incubation", "incubateur", "accelerateur", "accelerator", "incubator"),
    "research": ("recherche", "research", "postdoc", "post-doctorat"),
    "volunteering": ("volontariat", "benevolat", "volunteer", "volunteering"),
    "entrepreneurship": ("entrepreneuriat", "entrepreneurship", "creation d'entreprise"),
    "call_for_applications": ("appel a candidatures", "call for applications"),
}
WORK_MODE_TERMS = {
    "remote": ("teletravail", "a distance", "remote", "en ligne", "online"),
    "hybrid": ("hybride", "hybrid"),
    "onsite": ("presentiel", "sur site", "on site", "onsite"),
}
LANGUAGE_TERMS = {
    "en": ("en anglais", "anglophone", "in english", "english"),
    "fr": ("en francais", "francophone", "in french", "french"),
}
REGION_TERMS = {
    "cemac": ["CM", "GA", "CG", "TD", "CF", "GQ"],
    "afrique centrale": ["CM", "GA", "CG", "TD", "CF", "GQ", "CD"],
    "central africa": ["CM", "GA", "CG", "TD", "CF", "GQ", "CD"],
    "europe": ["FR", "BE", "DE", "CH", "GB"],
    "amerique du nord": ["CA", "US"],
    "north america": ["CA", "US"],
}
EDUCATION_TERMS = {
    "doctorate": ("doctorat", "phd"),
    "master": ("master", "msc", "mba"),
    "bachelor": ("licence", "bachelor", "undergraduate"),
    "bac_plus_2": ("bts", "bac+2"),
    "bac": ("baccalaureat",),
}
STOPWORDS = set(
    [
        "a",
        "au",
        "aux",
        "avec",
        "ce",
        "ces",
        "dans",
        "de",
        "des",
        "du",
        "en",
        "et",
        "for",
        "in",
        "la",
        "le",
        "les",
        "of",
        "on",
        "ou",
        "par",
        "pour",
        "sur",
        "the",
        "to",
        "un",
        "une",
        "je",
        "veux",
        "cherche",
        "recherche",
        "trouver",
        "trouve",
        "find",
        "looking",
        "need",
        "besoin",
        "moi",
        "my",
        "mon",
        "ma",
        "mes",
        "je",
        "suis",
        "i",
        "am",
        "an",
        "near",
        "pres",
        "2025",
        "2026",
        "2027",
        "2028",
        "2029",
        "2030",
        "annee",
        "year",
        "opportunite",
        "opportunites",
        "opportunity",
        "opportunities",
        "with",
        "years",
        "ans",
        "experience",
        "million",
        "millions",
        "mille",
        "fcfa",
        "xaf",
        "euro",
        "euros",
        "usd",
        "dollars",
        "minimum",
        "maximum",
        "moins",
        "plus",
        "less",
        "more",
        "than",
    ]
)
SYNONYMS = {
    "bourse": ["scholarship", "fellowship"],
    "scholarship": ["bourse"],
    "stage": ["internship"],
    "internship": ["stage"],
    "subvention": ["grant"],
    "grant": ["subvention"],
    "emploi": ["job"],
    "job": ["emploi"],
    "informatique": ["it", "software", "numerique"],
    "sante": ["health"],
    "agriculture": ["agribusiness", "agricole"],
    "energie": ["energy"],
    "education": ["enseignement"],
}
_AMOUNT = re.compile(
    r"(\d[\d\s.,]*)\s*(k|m|millions?|mille)?\s*(fcfa|xaf|f cfa|eur|euros?|€|usd|\$|dollars?)", re.IGNORECASE
)
_YEAR = re.compile(r"\b(20\d{2})\b")
_EXPERIENCE = re.compile(
    r"(\d{1,2})\s*(?:ans|annees|years?)\s*(?:d'experience|of experience|experience)", re.IGNORECASE
)


def interpret(text: str, countries: dict[str, str], today: date | None = None) -> dict[str, Any]:
    """``countries`` maps folded country names (FR/EN) → ISO codes."""
    today = today or date.today()
    f = f" {fold(text)} "
    filters: dict[str, Any] = {
        "raw": text.strip(),
        "categories": [],
        "countries": [],
        "languages": [],
        "keywords": [],
        "work_mode": None,
        "education": None,
        "experience_max_years": None,
        "amount_min": None,
        "amount_currency": None,
        "deadline_after": today.isoformat(),
        "deadline_before": None,
        "include_expired": False,
    }
    consumed: list[str] = []
    # CATEGORY_TERMS lists specific codes before their generic root, so the first match per
    # root is the most specific one ("bourse de master" -> scholarship.master, not scholarship).
    seen_roots: set[str] = set()
    for code, terms in CATEGORY_TERMS.items():
        hit = next((t for t in terms if f" {t} " in f), None)
        if hit is None:
            continue
        consumed.append(hit)
        root = code.split(".")[0]
        if root not in seen_roots:
            seen_roots.add(root)
            filters["categories"].append(code)

    for name, code in sorted(countries.items(), key=lambda kv: -len(kv[0])):
        if len(name) > 3 and f" {name} " in f and code not in filters["countries"]:
            filters["countries"].append(code)
            consumed.append(name)
    from collection.normalize import CITY_COUNTRY

    for city, code in CITY_COUNTRY.items():
        if f" {fold(city)} " in f and code not in filters["countries"]:
            filters["countries"].append(code)
    for region, codes in REGION_TERMS.items():
        if f" {region} " in f:
            filters["countries"].extend(c for c in codes if c not in filters["countries"])
            consumed.append(region)
    for mode, terms in WORK_MODE_TERMS.items():
        if any(f" {t} " in f for t in terms):
            filters["work_mode"] = mode
            consumed.extend(t for t in terms if f" {t} " in f)
            break
    for lang, terms in LANGUAGE_TERMS.items():
        if any(f" {t} " in f for t in terms):
            filters["languages"].append(lang)
            consumed.extend(t for t in terms if f" {t} " in f)
    for level, terms in EDUCATION_TERMS.items():
        if any(f" {t} " in f for t in terms):
            filters["education"] = level
            break
    m = _EXPERIENCE.search(f)
    if m:
        filters["experience_max_years"] = int(m.group(1))
    m = _AMOUNT.search(text)
    if m:
        raw = re.sub(r"[\s.,]", "", m.group(1))
        if raw.isdigit():
            value = int(raw)
            scale = (m.group(2) or "").lower()
            value *= 1_000 if scale in ("k", "mille") else 1_000_000 if scale.startswith(("m", "million")) else 1
            cur = fold(m.group(3))
            filters["amount_currency"] = (
                "XAF" if "cfa" in cur or "xaf" in cur else "EUR" if ("eur" in cur or "€" in cur) else "USD"
            )
            filters["amount_min"] = value
    years = [int(y) for y in _YEAR.findall(f)]
    future = [y for y in years if y >= today.year]
    if future:
        filters["deadline_after"] = today.isoformat()
    remaining = f
    for term in sorted(consumed, key=len, reverse=True):
        remaining = remaining.replace(f" {term} ", " ")
    words = [w for w in fold_words(remaining).split() if w not in STOPWORDS and len(w) > 2 and not w.isdigit()]
    # Keywords keep the user's spelling ("données", not "donnees"): they are shown as editable chips and
    # sent to sources that search server-side; local matching and FTS ignore accents anyway.
    typed = {fold(w): w.lower() for w in re.findall(r"\w+", text)}
    keywords: list[str] = []
    for w in words:
        shown = typed.get(w, w)
        if shown not in keywords:
            keywords.append(shown)
        for syn in SYNONYMS.get(w, []):
            if syn not in keywords:
                keywords.append(syn)
    filters["keywords"] = keywords[:12]
    return filters


def query_string(filters: dict[str, Any]) -> str:
    """Text sent to sources that support server-side search."""
    parts = list(filters.get("keywords") or [])
    if not parts:
        cat = (filters.get("categories") or ["opportunity"])[0].split(".")[-1].replace("_", " ")
        parts = [cat]
    return " ".join(parts[:6])
