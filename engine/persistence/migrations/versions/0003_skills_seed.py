"""Seed the skills reference (empty in the baseline) with common skills and FR/EN aliases.

Skills are also created on demand when a user enters one that is not in the list; this seed
only provides autocompletion and matching aliases from the first launch.

Revision ID: 0003_skills_seed
Revises: 0002_product_identity
"""

from __future__ import annotations

import unicodedata

import sqlalchemy as sa
from alembic import op

revision = "0003_skills_seed"
down_revision = "0002_product_identity"
branch_labels = None
depends_on = None

# (name, kind, aliases)
SKILLS: list[tuple[str, str, tuple[str, ...]]] = [
    ("Python", "technical", ()),
    ("Java", "technical", ()),
    ("JavaScript", "technical", ("js",)),
    ("TypeScript", "technical", ("ts",)),
    ("C#", "technical", ("csharp", "c sharp")),
    ("C++", "technical", ("cpp",)),
    ("PHP", "technical", ()),
    ("Dart", "technical", ()),
    ("Flutter", "technical", ()),
    ("Kotlin", "technical", ()),
    ("Swift", "technical", ()),
    ("Go", "technical", ("golang",)),
    ("Rust", "technical", ()),
    ("R", "technical", ("langage r",)),
    ("SQL", "technical", ()),
    ("PostgreSQL", "tool", ("postgres",)),
    ("MySQL", "tool", ()),
    ("MongoDB", "tool", ()),
    ("Django", "technical", ()),
    ("FastAPI", "technical", ()),
    ("Laravel", "technical", ()),
    ("Spring", "technical", ("spring boot",)),
    ("React", "technical", ("reactjs", "react.js")),
    ("Angular", "technical", ()),
    ("Vue.js", "technical", ("vue", "vuejs")),
    ("Node.js", "technical", ("node", "nodejs")),
    ("HTML", "technical", ("html5",)),
    ("CSS", "technical", ("css3",)),
    ("Développement web", "technical", ("web development", "developpement web")),
    ("Développement mobile", "technical", ("mobile development", "developpement mobile")),
    ("DevOps", "technical", ()),
    ("Docker", "tool", ()),
    ("Kubernetes", "tool", ("k8s",)),
    ("Linux", "tool", ()),
    ("Git", "tool", ("github", "gitlab")),
    ("Cloud computing", "technical", ("cloud", "aws", "azure", "gcp")),
    ("Cybersécurité", "technical", ("cybersecurity", "securite informatique", "sécurité informatique")),
    ("Réseaux informatiques", "technical", ("networking", "reseaux", "réseaux")),
    ("Administration système", "technical", ("system administration", "sysadmin")),
    ("Science des données", "technical", ("data science",)),
    ("Analyse de données", "technical", ("data analysis", "analyse de donnees")),
    ("Apprentissage automatique", "technical", ("machine learning", "ml")),
    ("Intelligence artificielle", "technical", ("artificial intelligence", "ia", "ai")),
    ("Statistiques", "technical", ("statistics",)),
    ("Excel", "tool", ("microsoft excel",)),
    ("Power BI", "tool", ()),
    ("SIG", "technical", ("gis", "système d'information géographique", "systeme d'information geographique")),
    ("QGIS", "tool", ()),
    ("AutoCAD", "tool", ()),
    ("SPSS", "tool", ()),
    ("Stata", "tool", ()),
    ("Gestion de projet", "domain", ("project management", "gestion de projets")),
    ("Méthodes agiles", "domain", ("agile", "scrum")),
    ("Suivi-évaluation", "domain", ("monitoring and evaluation", "m&e", "suivi evaluation")),
    ("Rédaction de propositions", "domain", ("proposal writing", "grant writing", "redaction de propositions")),
    ("Levée de fonds", "domain", ("fundraising", "levee de fonds")),
    ("Comptabilité", "domain", ("accounting", "comptabilite")),
    ("Finance", "domain", ()),
    ("Audit", "domain", ()),
    ("Fiscalité", "domain", ("taxation", "fiscalite")),
    ("Gestion des ressources humaines", "domain", ("human resources", "rh", "hr")),
    ("Marketing digital", "domain", ("digital marketing", "marketing numerique")),
    ("Communication", "domain", ()),
    ("Vente", "domain", ("sales",)),
    ("Logistique", "domain", ("logistics", "supply chain")),
    ("Passation des marchés", "domain", ("procurement", "passation de marches")),
    ("Droit des affaires", "domain", ("business law", "droit des affaires ohada", "ohada")),
    ("Santé publique", "domain", ("public health", "sante publique")),
    ("Agronomie", "domain", ("agronomy", "agriculture")),
    ("Environnement", "domain", ("environment", "climat", "climate")),
    ("Énergies renouvelables", "domain", ("renewable energy", "energies renouvelables")),
    ("Génie civil", "domain", ("civil engineering", "genie civil")),
    ("Électricité", "domain", ("electrical engineering", "electricite")),
    ("Enseignement", "domain", ("teaching", "education")),
    ("Recherche scientifique", "domain", ("research", "recherche")),
    ("Entrepreneuriat", "domain", ("entrepreneurship",)),
    ("Plan d'affaires", "domain", ("business plan", "plan d'affaires")),
    ("Développement communautaire", "domain", ("community development", "developpement communautaire")),
    ("Genre et inclusion", "domain", ("gender", "genre", "inclusion")),
    ("Droits humains", "domain", ("human rights",)),
    ("Journalisme", "domain", ("journalism",)),
    ("Traduction", "domain", ("translation",)),
    ("Design graphique", "domain", ("graphic design", "design")),
    ("UX/UI", "domain", ("ux", "ui", "ux design")),
    ("Leadership", "soft", ()),
    ("Travail en équipe", "soft", ("teamwork", "travail d'equipe", "travail en equipe")),
    ("Communication interpersonnelle", "soft", ("interpersonal skills",)),
    ("Résolution de problèmes", "soft", ("problem solving", "resolution de problemes")),
    ("Esprit critique", "soft", ("critical thinking",)),
    ("Autonomie", "soft", ("autonomy", "self-motivated")),
    ("Gestion du temps", "soft", ("time management",)),
    ("Prise de parole en public", "soft", ("public speaking",)),
    ("Négociation", "soft", ("negotiation", "negociation")),
    ("Adaptabilité", "soft", ("adaptability", "adaptabilite")),
    ("Rédaction", "soft", ("writing", "redaction")),
    ("Créativité", "soft", ("creativity", "creativite")),
    ("Microsoft Office", "tool", ("ms office", "word", "powerpoint", "pack office")),
]


def _normalize(text: str) -> str:
    decomposed = unicodedata.normalize("NFKD", text.lower().strip())
    return "".join(c for c in decomposed if not unicodedata.combining(c))


def upgrade() -> None:
    bind = op.get_bind()
    for name, kind, aliases in SKILLS:
        norm = _normalize(name)
        bind.execute(
            sa.text("INSERT OR IGNORE INTO skills(name, normalized, kind) VALUES (:n, :norm, :k)"),
            {"n": name, "norm": norm, "k": kind},
        )
        skill_id = bind.execute(sa.text("SELECT id FROM skills WHERE normalized = :norm"), {"norm": norm}).scalar_one()
        for alias in (norm, *(_normalize(a) for a in aliases)):
            bind.execute(
                sa.text("INSERT OR IGNORE INTO skill_aliases(alias, skill_id) VALUES (:a, :s)"),
                {"a": alias, "s": skill_id},
            )


def downgrade() -> None:
    bind = op.get_bind()
    for name, _kind, _aliases in SKILLS:
        norm = _normalize(name)
        bind.execute(
            sa.text("DELETE FROM skills WHERE normalized = :norm AND id NOT IN (SELECT skill_id FROM user_skills)"),
            {"norm": norm},
        )
