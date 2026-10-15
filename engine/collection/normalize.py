"""Deterministic extraction and normalisation (EF-05.09, EF-05.10, EF-07.01..05, EF-09.01).

Every value produced here carries a provenance: ``explicit`` when the source states it
(structured field or a verbatim clause), ``inferred`` when deduced by rules. Nothing is
invented: a value that cannot be found stays ``None`` and the UI shows "Not specified".
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Any

from core.text import fold, fold_words, truncate_lines

# ---------------------------------------------------------------- categories
CATEGORY_RULES: list[tuple[str, tuple[str, ...]]] = [
    (
        "tender",
        (
            "appel d'offres",
            "appel d offres",
            "avis d'appel",
            "tender",
            "request for proposal",
            "rfp",
            "request for quotation",
            "rfq",
            "manifestation d'interet",
            "expression of interest",
            "ami ",
            "procurement",
            "passation de marche",
            "dao ",
            "sollicitation de prix",
        ),
    ),
    (
        "scholarship",
        (
            "bourse",
            "scholarship",
            "fellowship",
            "full funded",
            "fully funded",
            "fully-funded",
            "financement d'etudes",
            "study grant",
            "bursary",
        ),
    ),
    ("internship", ("stage", "stagiaire", "internship", "intern ", "graduate trainee", "apprentissage")),
    (
        "grant",
        (
            "subvention",
            "grant",
            "appel a projets",
            "call for proposals",
            "funding opportunity",
            "financement",
            "fonds",
            "seed funding",
            "micro-grant",
            "microgrant",
        ),
    ),
    ("competition", ("concours", "competition", "prize", "prix ", "award", "challenge", "hackathon", "contest")),
    ("acceleration", ("incubat", "accelerat", "bootcamp startup", "programme d'acceleration")),
    (
        "training",
        (
            "formation",
            "training",
            "course",
            "cours en ligne",
            "mooc",
            "certification",
            "workshop",
            "atelier",
            "summer school",
            "ecole d'ete",
            "webinar",
        ),
    ),
    (
        "research",
        (
            "phd position",
            "postdoc",
            "post-doctoral",
            "postdoctoral",
            "research fellow",
            "chercheur",
            "these de doctorat",
            "doctoral position",
            "research grant",
        ),
    ),
    ("volunteering", ("volontariat", "volontaire", "volunteer", "benevol")),
    (
        "call_for_applications",
        ("appel a candidatures", "call for applications", "applications are open", "candidatures ouvertes"),
    ),
    ("partnership", ("partenariat", "partnership", "consortium")),
    ("entrepreneurship", ("entrepreneur", "startup", "start-up", "pme", "sme", "creation d'entreprise")),
    ("freelance", ("freelance", "consultant independant", "independent consultant", "mission de consultance")),
    (
        "employment",
        (
            "recrute",
            "recrutement",
            "offre d'emploi",
            "job",
            "vacancy",
            "vacancies",
            "poste",
            "position",
            "hiring",
            "we are looking for",
            "nous recherchons",
            "cdi",
            "cdd",
        ),
    ),
]
SUBCATEGORY_RULES: dict[str, list[tuple[str, tuple[str, ...]]]] = {
    "scholarship": [
        ("scholarship.phd", ("phd", "doctorat", "doctoral")),
        ("scholarship.master", ("master", "msc", "mba")),
        ("scholarship.bachelor", ("licence", "bachelor", "undergraduate")),
        ("scholarship.short_course", ("short course", "formation courte", "summer school")),
    ],
    "grant": [
        ("grant.startup", ("startup", "start-up", "entrepreneur")),
        ("grant.research", ("research", "recherche")),
        ("grant.association", ("association", "ong", "ngo", "civil society", "societe civile")),
        ("grant.individual", ("individual", "individuel")),
    ],
    "tender": [
        (
            "tender.it_services",
            ("informatique", "logiciel", "software", "it services", "systeme d'information", "digital", "numerique"),
        ),
        ("tender.works", ("travaux", "construction", "works")),
        ("tender.supplies", ("fourniture", "supply", "supplies", "equipment", "equipement")),
    ],
    "employment": [
        ("employment.consultancy", ("consultant", "consultancy", "consultance")),
        (
            "employment.international_org",
            (
                "united nations",
                "nations unies",
                "unicef",
                "undp",
                "pnud",
                "world bank",
                "banque mondiale",
                "who ",
                "oms",
            ),
        ),
    ],
}


def classify(title: str, text: str, hints: list[str] | None = None) -> tuple[str, str | None, float]:
    """Return (category code, subcategory code or None, confidence)."""
    head = f" {fold(title)} "
    body = f" {fold(text[:3000])} {fold(' '.join(hints or []))} "
    best: tuple[str, float] = ("other", 0.0)
    for code, words in CATEGORY_RULES:
        score = sum(2.0 for w in words if w in head) + sum(0.5 for w in words if w in body)
        if score > best[1]:
            best = (code, score)
    code, score = best
    sub = None
    for sub_code, words in SUBCATEGORY_RULES.get(code, []):
        if any(w in head or w in body for w in words):
            sub = sub_code
            break
    return code, sub, min(1.0, score / 4.0)


# ---------------------------------------------------------------- deadlines
_DEADLINE_CUES = re.compile(
    r"(date limite[^.:\n]{0,40}|deadline[^.:\n]{0,30}|closing date|date de cl[oô]ture|cl[oô]ture des (?:candidatures|"
    r"inscriptions|d[ée]p[oô]ts)|au plus tard (?:le)?|avant le|apply (?:by|before)|applications? (?:close|due)|"
    r"due date|soumission (?:avant|au plus tard)|jusqu'au|until)\s*[:\-–]?\s*",
    re.IGNORECASE,
)
_FR_MONTHS = (
    "janvier|février|fevrier|mars|avril|mai|juin|juillet|août|aout|septembre|octobre|novembre|décembre|decembre"
)
_EN_MONTHS = "january|february|march|april|may|june|july|august|september|october|november|december"
_DATE_PHRASE = re.compile(
    rf"(\d{{1,2}}(?:er)?\s+(?:{_FR_MONTHS}|{_EN_MONTHS}|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\.?,?\s+\d{{4}}"
    rf"|(?:{_EN_MONTHS}|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\.?\s+\d{{1,2}}(?:st|nd|rd|th)?,?\s+\d{{4}}"
    r"|\d{4}-\d{2}-\d{2}"
    r"|\d{1,2}[/.]\d{1,2}[/.]\d{4})",
    re.IGNORECASE,
)


def parse_date(value: str | None, *, prefer_dmy: bool = True) -> date | None:
    if not value:
        return None
    v = str(value).strip()
    iso = re.match(r"^(\d{4})-(\d{2})-(\d{2})", v)
    if iso:
        try:
            return date(int(iso.group(1)), int(iso.group(2)), int(iso.group(3)))
        except ValueError:
            return None
    import dateparser

    parsed = dateparser.parse(
        v,
        languages=["fr", "en"],
        settings={
            "DATE_ORDER": "DMY" if prefer_dmy else "MDY",
            "PREFER_DAY_OF_MONTH": "last",
            "RETURN_AS_TIMEZONE_AWARE": False,
            "STRICT_PARSING": True,
        },
    )
    return parsed.date() if isinstance(parsed, datetime) else None


def find_deadline(text: str) -> tuple[date | None, str | None]:
    """Deadline and the verbatim sentence it came from (EF-05.10)."""
    for cue in _DEADLINE_CUES.finditer(text):
        window = text[cue.start() : cue.end() + 80]
        m = _DATE_PHRASE.search(window)
        if m:
            d = parse_date(m.group(0))
            if d:
                start = text.rfind("\n", 0, cue.start()) + 1
                end = text.find("\n", cue.end())
                sentence = text[start : end if end != -1 else len(text)].strip()
                return d, sentence[:300]
    return None, None


# ------------------------------------------------------------------ amounts
_CURRENCY_TOKENS = [
    (r"f\s?cfa|fcfa|xaf|francs? cfa", "XAF"),
    (r"xof", "XOF"),
    (r"€|eur(?:os?)?\b", "EUR"),
    (r"us\$|usd|\$|dollars? (?:am[ée]ricains?|us)", "USD"),
    (r"£|gbp", "GBP"),
    (r"cad|c\$", "CAD"),
    (r"chf", "CHF"),
    (r"ngn|naira|₦", "NGN"),
    (r"zar|rand", "ZAR"),
    (r"mad|dirhams?", "MAD"),
]
_NUM = r"(?P<num>\d{1,3}(?:[ .,\u00a0\u202f]\d{3})+|\d+(?:[.,]\d+)?)"
_SCALE = r"(?:\s*(?P<scale>k|m|millions?|mio|milliards?|bn)\b)?"
_AMOUNT_RES = [
    (re.compile(rf"(?P<cur>{tok})\s*{_NUM}{_SCALE}", re.IGNORECASE), code) for tok, code in _CURRENCY_TOKENS
] + [
    (re.compile(rf"{_NUM}{_SCALE}\s*(?:d['’]\s*|de\s+)?(?P<cur>{tok})", re.IGNORECASE), code)
    for tok, code in _CURRENCY_TOKENS
]
MINOR_UNITS = {"XAF": 0, "XOF": 0}


def _to_number(raw: str, scale: str | None) -> float | None:
    digits = raw.replace(" ", " ").replace(" ", " ")
    if re.match(r"^\d{1,3}([ .,]\d{3})+$", digits):
        digits = re.sub(r"[ .,]", "", digits)
    else:
        digits = digits.replace(" ", "").replace(",", ".")
    try:
        value = float(digits)
    except ValueError:
        return None
    s = (scale or "").lower()
    if s == "k":
        value *= 1_000
    elif s in ("m", "million", "millions", "mio"):
        value *= 1_000_000
    elif s.startswith("milliard") or s == "bn":
        value *= 1_000_000_000
    return value


@dataclass
class Amount:
    currency: str
    minimum: int | None
    maximum: int | None
    raw: str


def find_amount(text: str) -> Amount | None:
    hits: list[tuple[int, str, float, str]] = []
    for rx, code in _AMOUNT_RES:
        for m in rx.finditer(text[:20000]):
            value = _to_number(m.group("num"), m.group("scale"))
            if value is not None and value >= 10:
                hits.append((m.start(), code, value, m.group(0).strip()))
    if not hits:
        return None
    hits.sort()
    currency = hits[0][1]
    values = sorted({h[2] for h in hits if h[1] == currency})
    factor = 10 ** MINOR_UNITS.get(currency, 2)
    lo, hi = values[0], values[-1]
    return Amount(currency, round(lo * factor), round(hi * factor) if hi != lo else None, hits[0][3])


# ------------------------------------------------------- countries / language
CITY_COUNTRY = {
    "douala": "CM",
    "yaounde": "CM",
    "bafoussam": "CM",
    "garoua": "CM",
    "bamenda": "CM",
    "buea": "CM",
    "kribi": "CM",
    "libreville": "GA",
    "brazzaville": "CG",
    "ndjamena": "TD",
    "n'djamena": "TD",
    "bangui": "CF",
    "malabo": "GQ",
    "kinshasa": "CD",
    "dakar": "SN",
    "abidjan": "CI",
    "lagos": "NG",
    "abuja": "NG",
    "nairobi": "KE",
    "kigali": "RW",
    "paris": "FR",
}


@dataclass
class CountryIndex:
    names: dict[str, str]  # folded name -> ISO code

    @classmethod
    def from_rows(cls, rows: list[dict[str, Any]]) -> CountryIndex:
        names: dict[str, str] = {}
        for r in rows:
            names[fold(r["name_fr"])] = r["code"]
            names[fold(r["name_en"])] = r["code"]
            names[r["code"].lower()] = r["code"]
        names.update({"cameroon": "CM", "cameroun": "CM", "rdc": "CD", "usa": "US", "uk": "GB"})
        return cls(names)

    def resolve(self, value: str | None) -> str | None:
        if not value:
            return None
        f = fold(str(value))
        if f in self.names:
            return self.names[f]
        return CITY_COUNTRY.get(f)

    def find_in(self, text: str) -> list[str]:
        f = f" {fold_words(text[:5000])} "
        found: dict[str, int] = {}
        for name, code in self.names.items():
            if len(name) > 3 and f" {name} " in f:
                found[code] = found.get(code, 0) + f.count(f" {name} ")
        for city, code in CITY_COUNTRY.items():
            if f" {fold_words(city)} " in f:
                found[code] = found.get(code, 0) + 1
        return [c for c, _n in sorted(found.items(), key=lambda kv: -kv[1])]


def detect_language(text: str) -> str | None:
    if len(text) < 40:
        return None
    try:
        from langdetect import DetectorFactory, detect

        DetectorFactory.seed = 0
        code = detect(text[:2000])
    except Exception:  # noqa: BLE001 - undetectable text
        return None
    return code if code in ("fr", "en", "es", "pt", "de", "ar", "zh", "sw") else None


def detect_work_mode(text: str) -> str | None:
    f = fold(text[:5000])
    if re.search(r"\b(hybrid|hybride)\b", f):
        return "hybrid"
    if re.search(r"\b(remote|teletravail|a distance|full[- ]remote|work from home|telecommute)\b", f):
        return "remote"
    if re.search(r"\b(on[- ]site|onsite|presentiel|sur site|in[- ]office)\b", f):
        return "onsite"
    return None


# --------------------------------------------------- eligibility/requirements
_ELIGIBILITY_CUES = re.compile(
    r"(eligib|[ée]ligib|conditions? d'(?:admission|[ée]ligibilit[ée]|acc[eè]s)|crit[eè]res|who can apply|"
    r"qui peut (?:postuler|candidater)|profil recherch|requirements|qualifications|must (?:be|have)|doit [eê]tre|"
    r"doivent [eê]tre|open to|ouvert aux)",
    re.IGNORECASE,
)
_EXPERIENCE = re.compile(
    r"(\d{1,2})\s*(?:\+\s*)?(?:ans|ann[ée]es|years?)\s+(?:d['’]\s?exp[ée]rience|of (?:relevant |"
    r"professional |work )?experience|minimum d['’]exp)",
    re.IGNORECASE,
)
_EDUCATION = [
    ("doctorate", r"\b(phd|doctorat|doctorate|ph\.d)\b"),
    ("master", r"\b(master|msc|mba|bac\s?\+\s?5)\b"),
    ("bachelor", r"\b(licence|bachelor|bsc|bac\s?\+\s?3)\b"),
    ("bac_plus_2", r"\b(bts|dut|hnd|bac\s?\+\s?2)\b"),
    ("bac", r"\b(baccalaur[ée]at|high school diploma)\b"),
]
_LANG_REQ = [
    ("en", r"(anglais|english)"),
    ("fr", r"(fran[cç]ais|french)"),
    ("es", r"(espagnol|spanish)"),
    ("pt", r"(portugais|portuguese)"),
    ("ar", r"(arabe|arabic)"),
    ("de", r"(allemand|german)"),
]
_LANG_CONTEXT = (
    r"(ma[iî]trise|courant|fluent|fluency|bilingue|bilingual|proficien|parl[ée]|written and spoken|"
    r"excellent|good command|bonne connaissance|working knowledge)"
)
_DOCUMENT_CUES = re.compile(
    r"(cv|curriculum vitae|lettre de motivation|cover letter|motivation letter|"
    r"relev[ée]s? de notes|transcripts?|lettres? de recommandation|recommendation letters?|"
    r"passeport|passport|copie (?:du|de la) dipl[oô]me|diploma copy|certificat|"
    r"plan d'affaires|business plan|budget pr[ée]visionnel)",
    re.IGNORECASE,
)


@dataclass
class Requirement:
    req_type: str
    label: str
    original_text: str
    min_level: str | None = None
    language_code: str | None = None
    skill_name: str | None = None


def sentences(text: str) -> list[str]:
    parts = re.split(r"(?<=[.!?;])\s+|\n+", text)
    return [p.strip(" -•*\t") for p in parts if len(p.strip()) > 3]


_ELIGIBILITY_HEADING = re.compile(
    r"^(conditions?( d['’](?:[ée]ligibilit[ée]|admission|acc[eè]s))?|[ée]ligibilit[ée]|eligibility( criteria)?|"
    r"crit[eè]res( d['’][ée]ligibilit[ée])?|who can apply|qui peut (?:postuler|candidater)|requirements|"
    r"profil (?:recherch[ée]|requis)|qualifications)\s*:?$",
    re.IGNORECASE,
)
_PERSONAL_CUES = re.compile(
    r"(ressortissant|nationalit|citizen|resident|r[ée]sid|[âa]g[ée]e?s? de|age limit|"
    r"years old|under the age|moins de \d+ ans)",
    re.IGNORECASE,
)


def eligibility_clauses(text: str, limit: int = 10) -> str | None:
    """Verbatim eligibility clauses: cue sentences plus everything under an eligibility heading."""
    clauses: list[str] = []
    in_section = 0
    for line in (ln.strip() for ln in text[:30000].split("\n")):
        if not line:
            continue
        if _ELIGIBILITY_HEADING.match(line):
            in_section = 6
            continue
        is_heading = len(line.split()) <= 6 and not line.endswith((".", ";", ":"))
        if in_section and is_heading:
            in_section = 0
        for s in sentences(line):
            relevant = in_section or _ELIGIBILITY_CUES.search(s) or _PERSONAL_CUES.search(s)
            if relevant and s not in clauses:
                clauses.append(s)
        if in_section:
            in_section -= 1
    return "\n".join(clauses[:limit])[:4000] or None


def extract_requirements(
    text: str, skill_aliases: dict[str, str]
) -> tuple[list[Requirement], float | None, str | None]:
    reqs: list[Requirement] = []
    exp_years: float | None = None
    m = _EXPERIENCE.search(text)
    if m:
        exp_years = float(m.group(1))
        reqs.append(Requirement("experience", f"{m.group(1)}+", m.group(0), min_level=m.group(1)))
    education = None
    for level, rx in _EDUCATION:
        hit = re.search(rx, text, re.IGNORECASE)
        if hit:
            education = level
            sentence = next((s for s in sentences(text) if hit.group(0).lower() in s.lower()), hit.group(0))
            reqs.append(Requirement("education", level, sentence[:300], min_level=level))
            break
    for code, rx in _LANG_REQ:
        for s in sentences(text[:20000]):
            if re.search(rx, s, re.IGNORECASE) and re.search(_LANG_CONTEXT, s, re.IGNORECASE):
                reqs.append(Requirement("language", code, s[:300], language_code=code))
                break
    folded = f" {fold(text[:20000])} "
    seen: set[str] = set()
    for alias, name in skill_aliases.items():
        if len(alias) >= 3 and name not in seen and re.search(rf"(?<![\w]){re.escape(alias)}(?![\w])", folded):
            seen.add(name)
            reqs.append(Requirement("skill", name, name, skill_name=name))
            if len(seen) >= 15:
                break
    doc_seen: set[str] = set()
    for s in sentences(text[:20000]):
        for hit in _DOCUMENT_CUES.finditer(s):
            key = fold(hit.group(0))
            if key not in doc_seen:
                doc_seen.add(key)
                reqs.append(Requirement("document", hit.group(0).strip().capitalize(), s[:300]))
    return reqs, exp_years, education


# ------------------------------------------------------------------- result
@dataclass
class Normalized:
    title: str
    summary: str | None
    description: str
    category: str
    subcategory: str | None
    organization: str | None = None
    country_code: str | None = None
    eligible_regions: list[str] = field(default_factory=list)
    location_text: str | None = None
    language_code: str | None = None
    work_mode: str | None = None
    deadline: date | None = None
    deadline_raw: str | None = None
    published: date | None = None
    amount: Amount | None = None
    eligibility_raw: str | None = None
    experience_min_years: float | None = None
    education_required: str | None = None
    requirements: list[Requirement] = field(default_factory=list)
    provenance: dict[str, tuple[str, str | None, str]] = field(default_factory=dict)  # field -> (prov, evidence, by)


def normalize(
    item_title: str,
    item_summary: str,
    item_fields: dict[str, Any],
    detail_text: str,
    structured: dict[str, Any] | None,
    countries: CountryIndex,
    skill_aliases: dict[str, str],
    source_country: str | None,
    source_language: str | None,
) -> Normalized:
    s = structured or {}
    explicit = {**item_fields, **{k: v for k, v in s.items() if v}}
    title = str(s.get("title") or item_title).strip()[:300]
    description = (detail_text or str(explicit.get("description") or "") or item_summary).strip()
    full_text = "\n".join(t for t in (title, item_summary, description) if t)
    prov: dict[str, tuple[str, str | None, str]] = {}
    by_struct = "structured_data" if structured else "adapter"

    hints = [*item_fields.get("categories", []), str(item_fields.get("category") or "")]
    category, sub, _conf = classify(title, full_text, hints)
    prov["category"] = ("inferred", None, "rules")

    organization = explicit.get("organization")
    if organization:
        prov["organization_name"] = ("explicit", str(organization)[:200], by_struct)

    deadline: date | None = None
    deadline_raw: str | None = None
    if explicit.get("deadline"):
        deadline = parse_date(str(explicit["deadline"]))
        if deadline:
            deadline_raw = str(explicit["deadline"])
            prov["deadline_on"] = ("explicit", deadline_raw, by_struct)
    if deadline is None:
        deadline, deadline_raw = find_deadline(full_text)
        if deadline:
            prov["deadline_on"] = ("explicit", deadline_raw, "rules")

    published = parse_date(str(explicit.get("published"))) if explicit.get("published") else None

    country = countries.resolve(explicit.get("country")) if explicit.get("country") else None
    if country:
        prov["country_code"] = ("explicit", str(explicit.get("country")), by_struct)
    mentioned = countries.find_in(full_text)
    if not country and mentioned:
        country = mentioned[0]
        prov["country_code"] = ("inferred", None, "rules")
    if not country and source_country:
        country = source_country
        prov["country_code"] = ("inferred", None, "adapter")

    work_mode = explicit.get("work_mode") or detect_work_mode(full_text)
    if work_mode:
        prov["work_mode"] = ("explicit" if explicit.get("work_mode") else "inferred", None, "rules")

    language = detect_language(description or full_text) or source_language
    amount = None
    raw_amount = explicit.get("amount")
    if isinstance(raw_amount, dict) and raw_amount.get("currency") and raw_amount.get("min"):
        cur = str(raw_amount["currency"]).upper()
        factor = 10 ** MINOR_UNITS.get(cur, 2)
        try:
            lo = int(float(raw_amount["min"]) * factor)
            hi = int(float(raw_amount["max"]) * factor) if raw_amount.get("max") else None
            amount = Amount(cur, lo, hi, str(raw_amount))
            prov["amount"] = ("explicit", str(raw_amount)[:200], by_struct)
        except (TypeError, ValueError):
            amount = None
    if amount is None:
        amount = find_amount(full_text)
        if amount:
            prov["amount"] = ("explicit", amount.raw, "rules")

    eligibility = eligibility_clauses(full_text)
    if eligibility:
        prov["eligibility_raw"] = ("explicit", eligibility[:300], "rules")
    reqs, exp_years, education = extract_requirements(full_text, skill_aliases)
    if explicit.get("education_required"):
        prov["education_required"] = ("explicit", str(explicit["education_required"])[:200], by_struct)

    summary_source = item_summary or description
    summary = truncate_lines(summary_source, 5, 600) if summary_source else None
    if summary:
        prov["summary"] = ("generated" if summary != summary_source.strip() else "explicit", None, "rules")

    location = explicit.get("location")
    return Normalized(
        title=title,
        summary=summary,
        description=description[:100_000],
        category=sub or category,
        subcategory=sub,
        organization=str(organization)[:200] if organization else None,
        country_code=country,
        eligible_regions=mentioned[:10],
        location_text=str(location)[:200] if location else None,
        language_code=language,
        work_mode=work_mode,
        deadline=deadline,
        deadline_raw=deadline_raw,
        published=published,
        amount=amount,
        eligibility_raw=eligibility,
        experience_min_years=exp_years,
        education_required=str(explicit.get("education_required") or education or "") or None,
        requirements=reqs,
        provenance=prov,
    )
