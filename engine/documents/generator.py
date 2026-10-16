"""Deterministic document drafts built *only* from the validated profile (EF-10.06..10.10).

No sentence asserts a qualification that is not present in the profile. The integrity check
(:func:`integrity_flags`) is also applied to every user edit and to AI-assisted drafts.
"""

from __future__ import annotations

import io
import re
from datetime import date
from typing import Any

from core.text import fold

DOC_TYPES = (
    "cover_letter",
    "scholarship_statement",
    "grant_proposal",
    "project_summary",
    "application_email",
    "cv_suggestions",
    "interview_prep",
    "checklist",
)
DEGREE_PATTERN = re.compile(
    r"\b(master|licence|bachelor|doctorat|phd|mba|msc|bsc|bts|dut|hnd|baccalaur[ée]at|"
    r"dipl[ôo]me d['’]ing[ée]nieur|ing[ée]nieur)\b[^.\n,;]{0,80}",
    re.IGNORECASE,
)
_MONTHS_FR = [
    "janvier",
    "février",
    "mars",
    "avril",
    "mai",
    "juin",
    "juillet",
    "août",
    "septembre",
    "octobre",
    "novembre",
    "décembre",
]


def _today(lang: str) -> str:
    d = date.today()
    return f"{d.day} {_MONTHS_FR[d.month - 1]} {d.year}" if lang == "fr" else d.strftime("%B %d, %Y")


def _join(items: list[str], lang: str) -> str:
    if not items:
        return ""
    if len(items) == 1:
        return items[0]
    return ", ".join(items[:-1]) + (" et " if lang == "fr" else " and ") + items[-1]


def header(doc_type: str, profile: dict[str, Any], lang: str) -> str:
    """Sender block for letters, filled locally so the AI never receives name or contact details."""
    if doc_type not in ("cover_letter", "scholarship_statement", "application_email"):
        return ""
    g = profile["general"]
    city = ", ".join(x for x in [g.get("city"), g.get("country_code")] if x)
    lines = [x for x in (g.get("full_name"), city) if x]
    return ("\n".join(lines) + "\n\n" if lines else "") + f"{_today(lang)}\n\n"


def build(doc_type: str, profile: dict[str, Any], opp: dict[str, Any], lang: str) -> tuple[str, str]:
    """Return (title, markdown content)."""
    fr = lang == "fr"
    g = profile["general"]
    name = g.get("full_name") or ""
    org = opp.get("organization_name") or ("l'organisme" if fr else "your organisation")
    title = opp["title"]
    skills = [s["name"] for s in profile["skills"]][:6]
    edu = profile["education"][0] if profile["education"] else None
    exp = profile["experiences"][0] if profile["experiences"] else None
    langs = [f"{x['language_code'].upper()} ({x['cefr_level']})" for x in profile["languages"]]
    city = ", ".join(x for x in [g.get("city"), g.get("country_code")] if x)
    summary = g.get("summary_text") if g.get("summary_approved") else None

    if doc_type == "cover_letter":
        head = (
            f"{name}\n{city}\n\n{_today(lang)}\n\n"
            + ("Objet : candidature — " if fr else "Subject: application — ")
            + title
        )
        body = []
        body.append(
            (
                "Madame, Monsieur,\n\nJe vous adresse ma candidature pour « {t} » publiée par {o}."
                if fr
                else "Dear Sir or Madam,\n\nI am applying for “{t}” published by {o}."
            ).format(t=title, o=org)
        )
        if exp:
            body.append(
                (
                    f"Je travaille actuellement comme {exp['job_title']} chez {exp['employer']}."
                    if exp.get("is_current")
                    else f"J'ai occupé le poste de {exp['job_title']} chez {exp['employer']}."
                )
                if fr
                else (
                    f"I currently work as {exp['job_title']} at {exp['employer']}."
                    if exp.get("is_current")
                    else f"I worked as {exp['job_title']} at {exp['employer']}."
                )
            )
        if edu:
            body.append(
                f"Je suis diplômé(e) en {edu['field_of_study']} ({edu['institution']})."
                if fr
                else f"I studied {edu['field_of_study']} at {edu['institution']}."
            )
        if skills:
            body.append(
                f"Mes compétences en {_join(skills, lang)} correspondent aux attentes de ce poste."
                if fr
                else f"My skills in {_join(skills, lang)} match the requirements of this role."
            )
        if langs:
            body.append(
                f"Je maîtrise les langues suivantes : {_join(langs, lang)}." if fr else f"I speak {_join(langs, lang)}."
            )
        body.append(
            "Je reste à votre disposition pour un entretien et vous prie d'agréer, Madame, Monsieur, "
            "l'expression de mes salutations distinguées."
            if fr
            else "I would welcome the opportunity to discuss my application.\n\nYours faithfully,"
        )
        content = head + "\n\n" + "\n\n".join(body) + f"\n\n{name}"
        return ("Lettre de motivation — " if fr else "Cover letter — ") + title, content

    if doc_type == "scholarship_statement":
        parts = [f"# {'Lettre de motivation — bourse' if fr else 'Scholarship statement'}", ""]
        if summary:
            parts += [summary, ""]
        if edu:
            parts.append(
                f"**{'Parcours académique' if fr else 'Academic background'} :** {edu['level']} — "
                f"{edu['field_of_study']}, {edu['institution']}."
            )
        if exp:
            parts.append(f"**{'Expérience' if fr else 'Experience'} :** {exp['job_title']}, {exp['employer']}.")
        objectives = [o["code"] for o in profile["objectives"]["items"]]
        parts += [
            "",
            f"**{'Motivation pour' if fr else 'Motivation for'} « {title} »**",
            "",
            (
                "[Expliquez ici, avec vos propres mots, pourquoi ce programme correspond à votre projet.]"
                if fr
                else "[Explain here, in your own words, why this programme fits your plans.]"
            ),
        ]
        if objectives:
            parts.append(
                ("Objectifs déclarés dans mon profil : " if fr else "Goals stated in my profile: ")
                + ", ".join(objectives)
            )
        return ("Lettre de bourse — " if fr else "Scholarship statement — ") + title, "\n".join(parts)

    if doc_type in ("project_summary", "grant_proposal"):
        project = profile["projects"][0] if profile["projects"] else None
        organization = profile.get("organization")
        parts = [
            f"# {('Résumé de projet' if doc_type == 'project_summary' else 'Proposition de subvention') if fr else ('Project summary' if doc_type == 'project_summary' else 'Grant proposal')} — {title}",
            "",
        ]
        if organization:
            parts.append(
                f"**{'Porteur' if fr else 'Applicant'} :** {organization['name']} ({organization['org_type']})"
            )
        if project:
            parts += [
                f"**{'Projet' if fr else 'Project'} :** {project['title']}",
                f"**{'Stade' if fr else 'Stage'} :** {project.get('stage') or '—'}",
                f"**Description :** {project.get('description') or '—'}",
                f"**{'Bénéficiaires' if fr else 'Beneficiaries'} :** {project.get('beneficiaries') or '—'}",
            ]
            if project.get("funding_min_minor") is not None:
                parts.append(
                    f"**{'Besoin de financement' if fr else 'Funding need'} :** "
                    f"{project['funding_min_minor']}–{project.get('funding_max_minor') or ''} "
                    f"{project.get('currency_code') or ''}"
                )
        else:
            parts.append(
                "[Aucun projet n'est décrit dans votre profil : ajoutez-le dans Mon profil › Projets.]"
                if fr
                else "[No project in your profile yet: add one in My profile › Projects.]"
            )
        if doc_type == "grant_proposal":
            sections = (
                [
                    "Contexte et problème",
                    "Objectifs",
                    "Activités",
                    "Résultats attendus",
                    "Budget",
                    "Calendrier",
                    "Suivi-évaluation",
                    "Durabilité",
                ]
                if fr
                else [
                    "Context and problem",
                    "Objectives",
                    "Activities",
                    "Expected results",
                    "Budget",
                    "Timeline",
                    "Monitoring and evaluation",
                    "Sustainability",
                ]
            )
            for s in sections:
                parts += [
                    "",
                    f"## {s}",
                    "[À compléter selon le canevas du bailleur.]"
                    if fr
                    else "[Complete following the funder's template.]",
                ]
        return parts[0].lstrip("# "), "\n".join(parts)

    if doc_type == "application_email":
        content = (
            (
                f"Objet : Candidature — {title}\n\nBonjour,\n\nVeuillez trouver ci-joint ma candidature pour "
                f"« {title} ». Vous trouverez mon CV et ma lettre de motivation en pièces jointes.\n\n"
                f"Cordialement,\n{name}"
            )
            if fr
            else (
                f"Subject: Application — {title}\n\nHello,\n\nPlease find attached my application for “{title}”, "
                f"including my CV and cover letter.\n\nKind regards,\n{name}"
            )
        )
        return ("Courriel de candidature — " if fr else "Application e-mail — ") + title, content

    if doc_type == "cv_suggestions":
        req_skills = opp.get("required_skills", [])
        have = {fold(s) for s in skills}
        missing = [s for s in req_skills if fold(s) not in have]
        matched = [s for s in req_skills if fold(s) in have]
        lines = [f"# {'Suggestions pour votre CV' if fr else 'CV suggestions'} — {title}", ""]
        if matched:
            lines.append(("Mettez en avant : " if fr else "Highlight: ") + ", ".join(matched))
        if missing:
            lines.append(
                (
                    "Compétences demandées absentes de votre profil (ne les ajoutez que si vous les avez réellement) : "
                    if fr
                    else "Requested skills missing from your profile (add them only if you really have them): "
                )
                + ", ".join(missing)
            )
        if not req_skills:
            lines.append(
                "L'annonce ne liste pas de compétences précises."
                if fr
                else "The listing does not name specific skills."
            )
        return lines[0].lstrip("# "), "\n".join(lines)

    if doc_type == "interview_prep":
        qs = (
            (
                [
                    "Présentez-vous en deux minutes.",
                    f"Pourquoi postulez-vous à « {title} » ?",
                    f"Que savez-vous de {org} ?",
                ]
                + [f"Décrivez une réalisation où vous avez utilisé {s}." for s in skills[:3]]
                + ["Quelles sont vos disponibilités ?"]
            )
            if fr
            else (
                [
                    "Introduce yourself in two minutes.",
                    f"Why are you applying for “{title}”?",
                    f"What do you know about {org}?",
                ]
                + [f"Describe an achievement where you used {s}." for s in skills[:3]]
                + ["When can you start?"]
            )
        )
        return (
            ("Préparation à l'entretien — " if fr else "Interview preparation — ") + title,
            "\n".join(f"- {q}" for q in qs),
        )

    raise ValueError(doc_type)


def integrity_flags(content: str, profile: dict[str, Any]) -> list[str]:
    """EF-10.10: degrees and employers asserted in the text but absent from the profile."""
    known = " ".join(fold(f"{e['level']} {e['field_of_study']} {e['institution']}") for e in profile["education"])
    known += " " + " ".join(fold(c["name"]) for c in profile["certifications"])
    employers = {fold(e["employer"]) for e in profile["experiences"]}
    flags: list[str] = []
    for m in DEGREE_PATTERN.finditer(content):
        degree = fold(m.group(1))
        if degree not in known and not (degree == "ingenieur" and "ingenieur" in known):
            flags.append(f"degree_not_in_profile:{m.group(0).strip()[:80]}")
    for m in re.finditer(r"\b(?:chez|at|pour le compte de|employed by)\s+([A-Z][\w&.\- ]{2,60})", content):
        employer = fold(m.group(1).strip())
        known_employer = any(employer.startswith(e) or e.startswith(employer) for e in employers)
        placeholder = any(w in employer for w in ("l'organisme", "your organisation"))
        if employer and not known_employer and not placeholder:
            flags.append(f"employer_not_in_profile:{m.group(1).strip()[:60]}")
    return flags


def to_docx(title: str, content: str) -> bytes:
    import docx
    from docx.shared import Pt

    d = docx.Document()
    style = d.styles["Normal"]
    style.font.name = "Calibri"
    style.font.size = Pt(11)
    d.core_properties.title = title
    d.core_properties.author = "Opportunex"
    for line in content.split("\n"):
        if line.startswith("## "):
            d.add_heading(line[3:], level=2)
        elif line.startswith("# "):
            d.add_heading(line[2:], level=1)
        elif line.startswith("- "):
            d.add_paragraph(line[2:], style="List Bullet")
        else:
            p = d.add_paragraph()
            for part in re.split(r"(\*\*[^*]+\*\*)", line):
                run = p.add_run(part[2:-2] if part.startswith("**") else part)
                run.bold = part.startswith("**")
    buf = io.BytesIO()
    d.save(buf)
    return buf.getvalue()


def to_pdf(title: str, content: str) -> bytes:
    from xml.sax.saxutils import escape

    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import cm
    from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer

    buf = io.BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=A4,
        title=title,
        author="Opportunex",
        leftMargin=2.2 * cm,
        rightMargin=2.2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )
    styles = getSampleStyleSheet()
    story: list[Any] = []
    for line in content.split("\n"):
        if not line.strip():
            story.append(Spacer(1, 6))
            continue
        text = escape(line)
        text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
        if line.startswith("## "):
            story.append(Paragraph(text[3:], styles["Heading2"]))
        elif line.startswith("# "):
            story.append(Paragraph(text[2:], styles["Heading1"]))
        elif line.startswith("- "):
            story.append(Paragraph("• " + text[2:], styles["BodyText"]))
        else:
            story.append(Paragraph(text, styles["BodyText"]))
    doc.build(story)
    return buf.getvalue()
