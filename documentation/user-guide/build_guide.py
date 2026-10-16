"""Build the Opportunex user guide (Word .docx) from real screenshots of the application.

Usage (from the repository root):
    engine/.venv/Scripts/python documentation/user-guide/build_guide.py

Screenshots
* ``screenshots/install_*.png`` and ``app_01_first_launch.png``: the real installer and the installed
  application, captured by ``tools/capture_installer.ps1`` (paths showing the Windows user name are pixelated).
* Every other screenshot is copied from ``apps/desktop/build/ui_tour/``, written by the UI tour integration test
  (``flutter test integration_test/ui_tour_test.dart -d windows``). It drives the real application and the real
  local engine; the people, institutions and offers shown are fictional sample data.
* ``ecran_principal_annote.png`` is the dashboard capture with numbered markers added by this script.

Only features present in version 1.0.0 are described; limited and unavailable ones are labelled as such.
"""

from __future__ import annotations

import shutil
import sys
from datetime import UTC, date, datetime
from pathlib import Path

from docx import Document
from docx.enum.section import WD_ORIENT
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SHOTS = HERE / "screenshots"
TOUR = ROOT / "apps" / "desktop" / "build" / "ui_tour"
LOGO = ROOT / "apps" / "desktop" / "assets" / "images" / "app_icon.png"
FONT = ROOT / "apps" / "desktop" / "assets" / "fonts" / "Inter-Bold.ttf"
OUT = HERE / "Guide_Utilisateur_Opportunex.docx"

VERSION = "1.0.0"
GUIDE_VERSION = "1.0"
NAVY = RGBColor(0x0B, 0x25, 0x4F)
BLUE = RGBColor(0x1E, 0x5B, 0xC6)
GREY = RGBColor(0x55, 0x5F, 0x6D)

# UI tour file → name in screenshots/ (French, stable).
FROM_TOUR = {
    "01_welcome": "bienvenue",
    "02_register": "creation_profil",
    "03_recovery_phrase": "phrase_recuperation",
    "04_onboarding_empty": "assistant_profil_vide",
    "light_dashboard": "tableau_de_bord",
    "dark_dashboard": "tableau_de_bord_sombre",
    "en_dashboard": "tableau_de_bord_anglais",
    "light_palette": "palette_commandes",
    "light_search": "recherche_criteres",
    "light_search_results": "recherche_resultats",
    "light_opportunity": "fiche_opportunite",
    "light_saved_list": "suivi_liste",
    "light_saved_board": "suivi_tableau",
    "light_saved_calendar": "suivi_calendrier",
    "light_application": "candidature",
    "light_monitors": "veilles",
    "light_workspaces": "espaces",
    "light_workspace": "espace_detail",
    "light_sources": "sources",
    "light_orgs": "organisations",
    "light_org": "organisation_detail",
    "light_profile": "profil",
    "light_cv_import": "import_cv",
    "light_settings_account": "parametres_compte",
    "light_settings_preferences": "parametres_preferences",
    "light_settings_privacy": "parametres_confidentialite",
    "light_settings_ai": "parametres_ia",
    "light_settings_sync": "parametres_synchronisation",
    "light_settings_backups": "parametres_sauvegardes",
    "light_settings_maintenance": "parametres_maintenance",
    "light_settings_about": "parametres_a_propos",
    "light_legal": "mentions_legales",
    "99_locked": "verrouillage",
    "99_recover": "recuperation",
}

# Areas pixelated in the guide copies (x0, y0, x1, y1 in the 1440 × 900 capture): folder paths that contain
# the Windows user name of the machine where the screenshots were taken.
MASKS: dict[str, list[tuple[int, int, int, int]]] = {
    "parametres_sauvegardes": [(486, 340, 1145, 383)],
    "parametres_maintenance": [(666, 287, 1105, 311)],
}

# Numbered markers on the dashboard (x, y in the 1440 × 900 capture) and their legend.
MARKERS = [
    ((232, 92), "Menu principal : une entrée par module (Ctrl+1 à Ctrl+9)."),
    ((232, 822), "Profil ouvert et mode (local ou synchronisé) ; cliquez pour changer de profil ou verrouiller."),
    ((156, 872), "Réduire ou déplier le menu."),
    ((452, 40), "Titre de la page et sous-titre."),
    ((1135, 58), "Action principale de la page (ici « Nouvelle recherche »)."),
    ((270, 92), "Compteurs : découvertes, nouvelles, pertinentes, sauvegardées, en préparation, soumises."),
    ((470, 268), "Échéances à venir (7, 14 et 30 jours)."),
    ((480, 490), "Recommandations : opportunités ouvertes les mieux classées pour votre profil."),
    ((1190, 268), "Candidatures par statut et prochains événements."),
    ((1130, 482), "Activité récente, état des sources, statistiques personnelles."),
]


# --------------------------------------------------------------------------------------------- images
def collect_screenshots() -> None:
    SHOTS.mkdir(parents=True, exist_ok=True)
    if not TOUR.exists():
        print(f"UI tour folder not found ({TOUR}); using the screenshots already in {SHOTS}")
        return
    for src, dest in FROM_TOUR.items():
        path = TOUR / f"{src}.png"
        if path.exists():
            shutil.copyfile(path, SHOTS / f"{dest}.png")
            if dest in MASKS:
                pixelate(SHOTS / f"{dest}.png", MASKS[dest])
        else:
            print(f"missing in UI tour: {src}.png")


def pixelate(path: Path, boxes: list[tuple[int, int, int, int]]) -> None:
    img = Image.open(path).convert("RGB")
    for box in boxes:
        region = img.crop(box)
        w, h = region.size
        small = region.resize((max(1, w // 10), max(1, h // 10)), Image.Resampling.BILINEAR)
        img.paste(small.resize((w, h), Image.Resampling.NEAREST), box[:2])
    img.save(path)


def annotate_dashboard() -> None:
    src = SHOTS / "tableau_de_bord.png"
    if not src.exists():
        return
    img = Image.open(src).convert("RGB")
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(str(FONT), 17) if FONT.exists() else ImageFont.load_default()
    for i, ((x, y), _) in enumerate(MARKERS, start=1):
        r = 15
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(214, 69, 0), outline=(255, 255, 255), width=3)
        label = str(i)
        box = draw.textbbox((0, 0), label, font=font)
        draw.text((x - (box[2] - box[0]) / 2 - box[0], y - (box[3] - box[1]) / 2 - box[1]), label, fill="white", font=font)
    img.save(SHOTS / "ecran_principal_annote.png")


# --------------------------------------------------------------------------------------------- docx helpers
class Guide:
    def __init__(self) -> None:
        self.doc = Document()
        self.figure = 0
        self._styles()

    # Styles, margins, header and footer.
    def _styles(self) -> None:
        d = self.doc
        normal = d.styles["Normal"]
        normal.font.name = "Calibri"
        normal.font.size = Pt(11)
        normal.element.rPr.rFonts.set(qn("w:eastAsia"), "Calibri")
        normal.paragraph_format.space_after = Pt(6)
        normal.paragraph_format.line_spacing = 1.15
        for level, size in ((1, 18), (2, 14), (3, 12)):
            st = d.styles[f"Heading {level}"]
            st.font.name = "Calibri"
            st.font.size = Pt(size)
            st.font.bold = True
            st.font.color.rgb = NAVY if level == 1 else BLUE
            st.paragraph_format.space_before = Pt(18 if level == 1 else 12)
            st.paragraph_format.space_after = Pt(6)
            st.paragraph_format.keep_with_next = True
        cap = d.styles["Caption"]
        cap.font.size = Pt(9.5)
        cap.font.italic = True
        cap.font.color.rgb = GREY
        for s in d.sections:
            s.orientation = WD_ORIENT.PORTRAIT
            s.page_width, s.page_height = Cm(21), Cm(29.7)
            s.left_margin = s.right_margin = Cm(2.2)
            s.top_margin = s.bottom_margin = Cm(2.2)
        props = d.core_properties
        props.title = "Guide utilisateur Opportunex"
        props.subject = f"Opportunex {VERSION}"
        props.author = "Momo Godi Yvan — ETS Monthe Network"
        props.keywords = "Opportunex, guide utilisateur, bourses, emplois, appels d'offres"
        props.language = "fr-FR"
        props.comments = f"Guide utilisateur d'Opportunex {VERSION} — CC BY-SA 4.0"
        props.last_modified_by = "Momo Godi Yvan"
        props.created = props.modified = datetime.now(UTC).replace(tzinfo=None)
        props.revision = 1

    def header_footer(self) -> None:
        sec = self.doc.sections[0]
        sec.different_first_page_header_footer = True
        hp = sec.header.paragraphs[0]
        hp.text = f"Opportunex {VERSION} — Guide utilisateur"
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hp.runs[0].font.size = Pt(9)
        hp.runs[0].font.color.rgb = GREY
        fp = sec.footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = fp.add_run("Page ")
        run.font.size = Pt(9)
        self._field(fp, "PAGE", size=9)
        tail = fp.add_run(" — © 2026 Momo Godi Yvan / ETS Monthe Network — CC BY-SA 4.0")
        tail.font.size = Pt(9)
        tail.font.color.rgb = GREY

    @staticmethod
    def _field(paragraph, instr: str, size: float | None = None, placeholder: str = "1") -> None:
        def run_with(el: OxmlElement):
            r = paragraph.add_run()
            if size:
                r.font.size = Pt(size)
            r._r.append(el)
            return r

        begin = OxmlElement("w:fldChar")
        begin.set(qn("w:fldCharType"), "begin")
        run_with(begin)
        code = OxmlElement("w:instrText")
        code.set(qn("xml:space"), "preserve")
        code.text = f" {instr} "
        run_with(code)
        sep = OxmlElement("w:fldChar")
        sep.set(qn("w:fldCharType"), "separate")
        run_with(sep)
        r = paragraph.add_run(placeholder)
        if size:
            r.font.size = Pt(size)
        end = OxmlElement("w:fldChar")
        end.set(qn("w:fldCharType"), "end")
        run_with(end)

    def toc(self) -> None:
        p = self.doc.add_paragraph()
        self._field(
            p,
            'TOC \\o "1-2" \\h \\z \\u',
            placeholder="Table des matières : cliquez droit ici puis « Mettre à jour les champs » si elle n'apparaît pas.",
        )

    def page_break(self) -> None:
        self.doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)

    def h1(self, text: str, new_page: bool = True) -> None:
        if new_page:
            self.page_break()
        self.doc.add_heading(text, level=1)

    def title(self, text: str) -> None:
        para = self.doc.add_paragraph()
        run = para.add_run(text)
        run.bold = True
        run.font.size = Pt(18)
        run.font.color.rgb = NAVY

    def h2(self, text: str) -> None:
        self.doc.add_heading(text, level=2)

    def h3(self, text: str) -> None:
        self.doc.add_heading(text, level=3)

    def p(self, text: str, bold_prefix: str | None = None) -> None:
        para = self.doc.add_paragraph()
        if bold_prefix:
            para.add_run(bold_prefix).bold = True
        self._rich(para, text)

    @staticmethod
    def _rich(para, text: str) -> None:
        """``**gras**`` in the text becomes bold."""
        parts = text.split("**")
        for i, part in enumerate(parts):
            if part:
                para.add_run(part).bold = i % 2 == 1

    def bullets(self, items: list[str]) -> None:
        for it in items:
            para = self.doc.add_paragraph(style="List Bullet")
            self._rich(para, it)

    def steps(self, items: list[str], start: int = 1) -> None:
        for i, it in enumerate(items, start=start):
            para = self.doc.add_paragraph()
            para.paragraph_format.left_indent = Cm(0.9)
            para.paragraph_format.first_line_indent = Cm(-0.6)
            para.add_run(f"{i}.  ").bold = True
            self._rich(para, it)

    def note(self, text: str, kind: str = "Conseil") -> None:
        table = self.doc.add_table(rows=1, cols=1)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = table.rows[0].cells[0]
        shade = {"Conseil": "E8F0FD", "Important": "FDEFE3", "Limite": "F1F1F4"}.get(kind, "E8F0FD")
        tc_pr = cell._tc.get_or_add_tcPr()
        shd = OxmlElement("w:shd")
        shd.set(qn("w:val"), "clear")
        shd.set(qn("w:color"), "auto")
        shd.set(qn("w:fill"), shade)
        tc_pr.append(shd)
        para = cell.paragraphs[0]
        para.add_run(f"{kind} — ").bold = True
        self._rich(para, text)
        self.doc.add_paragraph()

    def figure_(self, name: str, caption: str, width_cm: float = 16.0, explain: str | None = None) -> None:
        path = SHOTS / f"{name}.png"
        if not path.exists():
            raise SystemExit(f"missing screenshot: {path}")
        self.figure += 1
        para = self.doc.add_paragraph()
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
        para.paragraph_format.keep_with_next = True
        para.add_run().add_picture(str(path), width=Cm(width_cm))
        cap = self.doc.add_paragraph(f"Figure {self.figure} — {caption}", style="Caption")
        cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        if explain:
            self.p(explain)

    def table(self, header: list[str], rows: list[list[str]], widths: list[float] | None = None) -> None:
        t = self.doc.add_table(rows=1, cols=len(header))
        t.style = "Light Grid Accent 1"
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        for i, h in enumerate(header):
            cell = t.rows[0].cells[i]
            cell.text = ""
            cell.paragraphs[0].add_run(h).bold = True
        for row in rows:
            cells = t.add_row().cells
            for i, v in enumerate(row):
                cells[i].text = ""
                self._rich(cells[i].paragraphs[0], v)
        if widths:
            for row in t.rows:
                for i, w in enumerate(widths):
                    row.cells[i].width = Cm(w)
        self.doc.add_paragraph()

    def save(self) -> None:
        self.doc.save(OUT)


# --------------------------------------------------------------------------------------------- content
def cover(g: Guide) -> None:
    d = g.doc
    for _ in range(3):
        d.add_paragraph()
    if LOGO.exists():
        para = d.add_paragraph()
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
        para.add_run().add_picture(str(LOGO), width=Cm(4))
    t = d.add_paragraph()
    t.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = t.add_run("Opportunex")
    r.bold = True
    r.font.size = Pt(36)
    r.font.color.rgb = NAVY
    s = d.add_paragraph()
    s.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = s.add_run("Trouvez · Analysez · Réalisez")
    r.font.size = Pt(14)
    r.font.color.rgb = BLUE
    d.add_paragraph()
    t2 = d.add_paragraph()
    t2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = t2.add_run("Guide utilisateur")
    r.bold = True
    r.font.size = Pt(24)
    sub = d.add_paragraph()
    sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = sub.add_run(f"Logiciel version {VERSION} · Guide version {GUIDE_VERSION} · {date.today().strftime('%d/%m/%Y')}")
    r.font.size = Pt(11)
    r.font.color.rgb = GREY
    for _ in range(6):
        d.add_paragraph()
    info = [
        ("Éditeur", "ETS Monthe Network"),
        ("Auteur principal", "Momo Godi Yvan"),
        ("Licence du logiciel", "GNU Affero General Public License v3 (AGPL-3.0-or-later)"),
        ("Licence de ce guide", "Creative Commons Attribution – Partage dans les mêmes conditions 4.0 (CC BY-SA 4.0)"),
        ("Plateformes", "Windows 10 (1809) et 11, 64 bits ; Linux Ubuntu 24.04+ / Debian 13, 64 bits (voir chapitre 4)"),
    ]
    for k, v in info:
        para = d.add_paragraph()
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
        para.paragraph_format.space_after = Pt(2)
        a = para.add_run(f"{k} : ")
        a.bold = True
        a.font.size = Pt(10)
        b = para.add_run(v)
        b.font.size = Pt(10)


def front_matter(g: Guide) -> None:
    g.h1("Informations sur le document")
    g.h2("Logiciel, éditeur et licence")
    g.table(
        ["Élément", "Valeur"],
        [
            ["Logiciel", f"Opportunex {VERSION}"],
            ["Éditeur", "ETS Monthe Network"],
            ["Auteur principal", "Momo Godi Yvan"],
            ["Licence", "GNU AGPL v3 : utilisation, étude, modification et redistribution libres. Si vous proposez "
             "une version modifiée à des utilisateurs à travers un réseau, vous devez leur en fournir le code source."],
            ["Marques", "Les noms et le logo Opportunex sont réservés (fichier TRADEMARKS.md)."],
            ["Composants tiers", "179 composants libres, listés dans THIRD_PARTY_NOTICES.md et dans l'application : "
             "Paramètres > À propos > Licences tierces."],
            ["Code source", "https://github.com/momogodi2000/OpportuNex"],
        ],
        [4.5, 12],
    )
    g.h2("Historique des versions du guide")
    g.table(
        ["Version du guide", "Date", "Logiciel", "Modifications"],
        [[GUIDE_VERSION, date.today().strftime("%d/%m/%Y"), VERSION, "Première édition."]],
        [3, 2.5, 2.5, 8.5],
    )
    g.h2("À propos des captures d'écran")
    g.p(
        "Toutes les captures proviennent de la version 1.0.0 réellement exécutée sous Windows 11 : l'installateur, "
        "puis l'application et son moteur local. Les personnes, établissements et offres visibles (par exemple "
        "« Awa Ndjock », « Université Exemple », « Banque Exemple ») sont **fictifs** : ils ont été créés pour les "
        "captures à partir d'un site de démonstration local. Les chemins contenant le nom d'utilisateur Windows "
        "ont été floutés. L'écran principal annoté (figure du chapitre 6) porte des repères numérotés ajoutés "
        "après la capture."
    )
    g.h2("Conventions")
    g.bullets([
        "**Gras** : nom d'un bouton, d'un menu ou d'un champ, tel qu'il apparaît à l'écran.",
        "Paramètres > Sauvegardes : chemin à suivre dans les menus.",
        "Ctrl+K : raccourci clavier (touches à presser ensemble).",
        "Les encadrés « Conseil », « Important » et « Limite » signalent une astuce, une précaution ou une "
        "restriction de la version actuelle.",
    ])
    g.page_break()
    g.title("Table des matières")
    g.toc()


def ch_presentation(g: Guide) -> None:
    g.h1("1. Présentation d'Opportunex")
    g.p(
        "Opportunex est une application de bureau libre qui aide à **trouver**, **analyser** et **suivre** des "
        "opportunités : bourses, emplois, stages, subventions, appels d'offres, concours, formations, volontariat… "
        "Elle s'adresse en priorité aux étudiants, jeunes diplômés, entrepreneurs et associations d'Afrique "
        "centrale, en français et en anglais."
    )
    g.h2("Objectifs")
    g.bullets([
        "Rassembler en une seule recherche des annonces publiées sur des sites publics (catalogue de 74 sources).",
        "Comprendre rapidement une annonce : fiche en 13 rubriques, chaque information étant reliée à l'extrait "
        "de l'annonce d'où elle provient.",
        "Mesurer l'intérêt d'une opportunité pour votre profil par un score explicable de 0 à 100 — sans jamais "
        "affirmer que vous êtes éligible lorsque l'annonce ne publie pas de critères précis.",
        "Suivre vos candidatures jusqu'à la réponse, avec rappels avant les dates limites.",
        "Garder vos données chez vous : tout est stocké chiffré sur votre ordinateur, sans télémétrie.",
    ])
    g.h2("Ce qu'Opportunex ne fait pas")
    g.bullets([
        "Il ne soumet **jamais** de candidature à votre place : vous postulez toujours sur le site officiel de "
        "l'organisme.",
        "Il ne garantit pas l'exactitude des annonces : vérifiez toujours les informations sur le lien officiel.",
        "Il n'utilise pas d'intelligence artificielle tant que vous ne l'avez pas activée vous-même (chapitre 7.11).",
    ])
    g.h2("Disponibilité des fonctions dans la version 1.0.0")
    g.p("Le tableau suivant distingue les fonctions disponibles, limitées et non disponibles dans cette version.")
    g.table(
        ["Fonction", "État", "Précisions"],
        [
            ["Profils locaux chiffrés, verrouillage, récupération", "Disponible", ""],
            ["Assistant de profil, import de CV", "Disponible", "CV numérisés (images) non lus : saisie manuelle."],
            ["Recherche en langage naturel, filtres, tri, export", "Disponible",
             "Filtres manuels : pays, catégorie, mots-clés, mode de travail, date limite, expirées. Les filtres par "
             "source, expérience et fourchette de montant ne sont pas encore proposés à l'écran."],
            ["Collecte des sources", "Limitée",
             "20 flux et API vérifiés ; les autres portails sont proposés en lien officiel à consulter vous-même. "
             "Annonces en PDF et sites nécessitant un navigateur : non lus."],
            ["Fiche d'opportunité, score de pertinence", "Disponible", ""],
            ["Suivi des candidatures, calendrier, rappels", "Disponible", ""],
            ["Brouillons de documents", "Disponible", "Sans IA : modèles remplis avec votre profil validé."],
            ["Veilles et notifications", "Limitée",
             "Uniquement lorsque l'application est ouverte (fenêtre ou zone de notification)."],
            ["Espaces de travail, comparaison", "Disponible", "Les veilles ne sont pas encore rattachées à un espace."],
            ["Assistance par IA", "Disponible (facultative)",
             "Nécessite votre propre fournisseur (clé d'API ou modèle local)."],
            ["Synchronisation chiffrée, organisations", "Limitée",
             "Nécessite un serveur auto-hébergé ; aucune instance officielle n'existe encore."],
            ["Sauvegarde et restauration", "Disponible", ""],
            ["Mises à jour automatiques", "Non disponible",
             "Téléchargez les nouvelles versions manuellement (chapitre 3)."],
            ["Partage public d'une opportunité par lien", "Non disponible", ""],
            ["Éditeur visuel de connecteurs, registre communautaire", "Non disponible", ""],
            ["Raccourcis clavier personnalisables", "Limitée", "Raccourcis fixes (chapitre 6.4)."],
            ["macOS", "Non disponible", "Version non testée et non distribuée."],
        ],
        [5.5, 2.8, 8.2],
    )


def ch_requirements(g: Guide) -> None:
    g.h1("2. Prérequis matériels et logiciels")
    g.table(
        ["", "Windows", "Linux"],
        [
            ["Système", "Windows 10 version 1809 ou plus récent, Windows 11 ; 64 bits (x64)",
             "Ubuntu 24.04 ou plus récent, Debian 13 ; 64 bits (amd64)"],
            ["Espace disque", "Environ 280 Mo pour l'application, plus vos données", "Environ 300 Mo"],
            ["Mémoire", "4 Go de RAM recommandés. Opportunex utilise environ 250 Mo au repos (mesuré : fenêtre "
             "110 Mo + moteur 135 Mo)", "4 Go de RAM recommandés"],
            ["Écran", "1280 × 720 recommandé (l'interface s'adapte aux fenêtres plus petites)", "Idem"],
            ["Réseau", "Connexion Internet pour la recherche ; tout le reste fonctionne hors ligne", "Idem"],
            ["Droits", "Aucun droit administrateur (installation pour l'utilisateur courant)",
             "Droits sudo pour installer le paquet"],
            ["Composants", "Aucun : tout est inclus", "GTK 3, libsecret (trousseau), libnotify — installés "
             "automatiquement par apt"],
        ],
        [3, 7, 6.5],
    )
    g.note("Pour l'IA facultative avec un modèle local (Ollama, LM Studio), prévoyez la mémoire demandée par ce "
           "modèle ; Opportunex lui-même n'en a pas besoin.", "Conseil")


def ch_windows(g: Guide) -> None:
    g.h1("3. Installation et désinstallation sous Windows")
    g.h2("3.1 Télécharger")
    g.p("Deux formats sont proposés pour chaque version, avec un fichier d'empreintes SHA256SUMS.txt :")
    g.bullets([
        "**Opportunex-Setup-1.0.0-x64.exe** : installateur (recommandé).",
        "**Opportunex-1.0.0-windows-x64-portable.zip** : version portable, sans installation.",
    ])
    g.p("Pour vérifier qu'un fichier n'a pas été altéré, comparez son empreinte avec celle de SHA256SUMS.txt :")
    g.p("Get-FileHash .\\Opportunex-Setup-1.0.0-x64.exe -Algorithm SHA256", bold_prefix="PowerShell : ")
    g.note("Les fichiers ne sont pas encore signés numériquement. Windows SmartScreen peut afficher « Windows a "
           "protégé votre ordinateur » : cliquez sur **Informations complémentaires** puis **Exécuter quand même**, "
           "après avoir vérifié l'empreinte.", "Important")
    g.h2("3.2 Installer")
    g.steps(["Double-cliquez sur le fichier d'installation. Choisissez le mode d'installation :"])
    g.figure_("install_01_mode", "Choix du mode d'installation", 9,
              "**Installer seulement pour moi (recommandé)** ne demande aucun droit administrateur. "
              "**Installer pour tous les utilisateurs** demande les droits administrateur.")
    g.steps(["Lisez la licence (GNU AGPL v3), cochez **Je comprends et j'accepte les termes du contrat de licence**, "
             "puis cliquez sur **Suivant**."], start=2)
    g.figure_("install_02_license", "Contrat de licence", 12)
    g.steps(["Gardez le dossier proposé (dans votre profil Windows) ou cliquez sur **Parcourir…**, puis **Suivant**."], start=3)
    g.figure_("install_03_folder", "Dossier de destination (chemin flouté)", 12)
    g.steps(["Cochez **Créer un raccourci sur le bureau** si vous le souhaitez, puis **Suivant**."], start=4)
    g.figure_("install_04_tasks", "Tâches supplémentaires", 12)
    g.steps(["Vérifiez le récapitulatif et cliquez sur **Installer**."], start=5)
    g.figure_("install_05_ready", "Prêt à installer (récapitulatif flouté)", 12)
    g.steps(["À la fin, laissez **Lancer Opportunex** coché et cliquez sur **Terminer**."], start=6)
    g.figure_("install_06_finished", "Fin de l'installation", 12)
    g.p("Un raccourci **Opportunex** est ajouté au menu Démarrer.")
    g.h2("3.3 Version portable")
    g.steps([
        "Décompressez le fichier ZIP dans un dossier de votre choix (par exemple Documents\\Opportunex).",
        "Lancez **opportunex.exe**. Ne déplacez pas ce fichier hors de son dossier : il a besoin du sous-dossier "
        "**engine**.",
    ])
    g.p("La version portable utilise le même dossier de données que la version installée (voir 7.5).")
    g.h2("3.4 Mettre à jour")
    g.p("La vérification automatique des mises à jour n'est pas encore disponible. Pour installer une nouvelle "
        "version, téléchargez-la et lancez son installateur : il remplace l'ancienne version en conservant vos "
        "données. Une sauvegarde de sécurité est créée automatiquement avant toute migration de la base.")
    g.h2("3.5 Où sont mes données ?")
    g.p("Dans le dossier **%APPDATA%\\PIO** (par exemple C:\\Users\\<vous>\\AppData\\Roaming\\PIO) : profils "
        "chiffrés, documents chiffrés, sauvegardes et journaux. Le dossier exact est affiché dans "
        "Paramètres > Maintenance.")
    g.h2("3.6 Désinstaller")
    g.steps([
        "Fermez Opportunex (icône de la zone de notification > **Quitter** si l'application y est réduite).",
        "Ouvrez Paramètres Windows > Applications > Applications installées, choisissez **Opportunex** puis "
        "**Désinstaller**.",
        "Une question vous demande s'il faut **aussi supprimer vos données** (profils, sauvegardes, journaux). "
        "Répondez **Non** pour les conserver — c'est le choix par défaut, recommandé si vous réinstallez.",
    ])
    g.p("La désinstallation retire aussi le lancement automatique à l'ouverture de session, s'il était activé.")


def ch_linux(g: Guide) -> None:
    g.h1("4. Installation sous Debian/Ubuntu")
    g.note("Le paquet .deb de la version 1.0.0 est produit par un script de construction qui n'a pas encore pu "
           "être exécuté et testé sur une machine Linux. Les instructions ci-dessous décrivent le paquet prévu ; "
           "vérifiez la disponibilité du fichier sur la page de publication.", "Limite")
    g.h2("4.1 Installer")
    g.steps([
        "Téléchargez **opportunex_1.0.0_amd64.deb** et SHA256SUMS.txt, puis vérifiez l'empreinte : "
        "sha256sum -c SHA256SUMS.txt",
        "Installez le paquet et ses dépendances : sudo apt install ./opportunex_1.0.0_amd64.deb",
        "Lancez **Opportunex** depuis le menu des applications, ou la commande opportunex.",
    ])
    g.p("L'application est installée dans /opt/opportunex. Vos données sont dans ~/.local/share/pio. Les clés "
        "d'API éventuelles sont rangées dans le trousseau du bureau (GNOME Keyring ou KWallet).")
    g.h2("4.2 Désinstaller")
    g.p("sudo apt remove opportunex", bold_prefix="Commande : ")
    g.p("Vos données dans ~/.local/share/pio sont conservées ; supprimez ce dossier vous-même si vous voulez les "
        "effacer.")


def ch_first_launch(g: Guide) -> None:
    g.h1("5. Premier lancement et configuration initiale")
    g.p("Au tout premier lancement, l'écran d'accueil s'affiche dans la langue et le thème de Windows. Sur la "
        "capture ci-dessous, Windows est en anglais et en thème sombre : choisissez **Français** pour passer "
        "l'application en français.")
    g.figure_("app_01_first_launch", "Premier lancement de l'application installée (Windows en anglais)", 15)
    g.figure_("bienvenue", "Écran d'accueil en français",
              explain="**Créer un profil** ouvre le formulaire d'inscription. **Importer un profil depuis une "
                      "sauvegarde** restaure un profil à partir d'un fichier de sauvegarde Opportunex (.opxbak).")
    g.h2("5.1 Créer votre profil local")
    g.steps([
        "Cliquez sur **Créer un profil**.",
        "Saisissez votre nom, votre adresse électronique et un mot de passe d'au moins **12 caractères**. "
        "L'indicateur de robustesse vous guide ; les mots de passe connus comme compromis sont refusés.",
        "Confirmez le mot de passe, acceptez les conditions d'utilisation, puis cliquez sur **Créer un compte**.",
    ])
    g.figure_("creation_profil", "Création d'un profil local")
    g.note("Ce profil est **local** : il n'est pas créé sur Internet. Votre adresse sert seulement à vous "
           "identifier sur cet ordinateur et, si vous l'activez plus tard, pour la synchronisation.", "Conseil")
    g.h2("5.2 Noter la phrase de récupération")
    g.p("Opportunex affiche ensuite **12 mots**. C'est le seul moyen de récupérer vos données si vous oubliez votre "
        "mot de passe : personne d'autre, pas même ETS Monthe Network, ne peut les déchiffrer.")
    g.figure_("phrase_recuperation", "Phrase de récupération de 12 mots (profil d'exemple)")
    g.p("Après la création du profil, le thème suit votre réglage de profil, par défaut celui de Windows "
        "(ici sombre). Vous pouvez le changer dans Paramètres > Compte et sécurité > Langue et apparence.")
    g.steps([
        "Recopiez les 12 mots dans l'ordre, sur papier, et rangez-les en lieu sûr.",
        "Cochez la case de confirmation, puis cliquez sur **Continuer**.",
    ])
    g.note("Ne photographiez pas la phrase et ne l'enregistrez pas dans un fichier non protégé.", "Important")
    g.h2("5.3 Assistant de profil")
    g.p("L'assistant en 7 étapes pré-remplit votre profil, utilisé pour le score de pertinence et les brouillons : "
        "informations générales et liens, formation, expérience, compétences et langues, objectifs, projet ou "
        "organisation, récapitulatif. Toutes les étapes sont facultatives : **Passer** ou **Plus tard** vous "
        "amènent au tableau de bord, et **Reprendre la configuration** y reste proposé.")
    g.figure_("assistant_profil_vide", "Assistant de profil, première étape")
    g.p("Vous pouvez aussi commencer par importer votre CV (chapitre 7.2).")


def ch_interface(g: Guide) -> None:
    g.h1("6. Présentation de l'interface et navigation")
    g.h2("6.1 L'écran principal")
    g.figure_("ecran_principal_annote", "Écran principal (tableau de bord) avec repères")
    g.table(["Repère", "Rôle"], [[str(i), t] for i, (_, t) in enumerate(MARKERS, start=1)], [2, 14.5])
    g.h2("6.2 Le menu principal")
    g.table(
        ["Entrée", "Raccourci", "Contenu"],
        [
            ["Tableau de bord", "Ctrl+1", "Vue d'ensemble, échéances, recommandations"],
            ["Recherche", "Ctrl+2", "Nouvelle recherche, résultats, historique"],
            ["Sauvegardées", "Ctrl+3", "Opportunités suivies : liste, tableau, calendrier"],
            ["Veilles", "Ctrl+4", "Recherches automatiques et notifications"],
            ["Espaces", "Ctrl+5", "Espaces de travail par projet"],
            ["Sources", "Ctrl+6", "Catalogue des sources et liens officiels"],
            ["Organisations", "Ctrl+7", "Organisations partagées (avec synchronisation)"],
            ["Mon profil", "Ctrl+8", "Profil, import de CV"],
            ["Paramètres", "Ctrl+9", "Compte, préférences, confidentialité, IA, synchronisation, sauvegardes, "
             "maintenance, à propos"],
        ],
        [3.5, 2.2, 10.8],
    )
    g.h2("6.3 La palette de commandes")
    g.p("Appuyez sur **Ctrl+K** pour ouvrir la palette, tapez quelques lettres (« sauvegarde », « thème »…) puis "
        "Entrée. Elle donne accès à toutes les pages et aux actions courantes : nouvelle recherche, nouvelle veille, "
        "ajout de source, import de CV, changement de thème, verrouillage.")
    g.figure_("palette_commandes", "Palette de commandes (Ctrl+K)")
    g.h2("6.4 Raccourcis clavier")
    g.table(
        ["Raccourci", "Action"],
        [
            ["Ctrl+K", "Palette de commandes"],
            ["Ctrl+F", "Nouvelle recherche"],
            ["Ctrl+1 à Ctrl+9", "Aller à une section du menu"],
            ["Ctrl+L", "Verrouiller le profil"],
            ["F1 ou Ctrl+/", "Afficher l'aide des raccourcis"],
            ["Échap", "Fermer une fenêtre de dialogue"],
            ["Tab / Maj+Tab", "Passer d'un élément à l'autre (navigation entièrement au clavier)"],
        ],
        [4, 12.5],
    )
    g.h2("6.5 Langue, thème et taille de fenêtre")
    g.p("Paramètres > Compte et sécurité > Langue et apparence permet de choisir le français ou l'anglais et le "
        "thème clair, sombre ou celui du système. L'interface s'adapte aux petites fenêtres (menu réduit à des icônes) et aux grandes tailles de "
        "texte de Windows.")
    g.figure_("tableau_de_bord_sombre", "Thème sombre", 13)
    g.figure_("tableau_de_bord_anglais", "Interface en anglais", 13)


def ch_modules(g: Guide) -> None:
    g.h1("7. Description des modules et procédures pas à pas")
    g.p("Ce chapitre décrit chaque module, avec ses procédures pas à pas à côté de l'écran concerné.")

    # 11.1 Profile
    g.h2("7.1 Mon profil")
    g.p("Le profil décrit votre parcours : informations générales, liens, formations, expériences, compétences, "
        "langues, objectifs, organisation éventuelle. Il sert au score de pertinence et aux brouillons ; il n'est "
        "jamais envoyé à un tiers sans votre consentement explicite. L'indicateur de complétude montre ce qui "
        "manque.")
    g.figure_("profil", "Mon profil")
    g.steps([
        "Ouvrez **Mon profil** (Ctrl+8).",
        "Cliquez sur le bouton de modification d'une rubrique, complétez les champs puis enregistrez.",
        "Pour retirer un élément (formation, expérience…), utilisez son bouton de suppression puis confirmez.",
    ])

    g.h2("7.2 Importer un CV")
    g.p("L'import pré-remplit le profil à partir d'un CV **PDF, DOCX ou TXT** de 10 Mo au plus. L'analyse se fait "
        "sur votre ordinateur. Rien n'est ajouté sans votre validation, élément par élément.")
    g.figure_("import_cv", "Import de CV")
    g.steps([
        "Mon profil > **Importer un CV** > **Choisir un fichier**.",
        "Pour chaque élément détecté, choisissez **Accepter**, corrigez-le, ou **Rejeter**.",
        "Choisissez de **conserver le fichier du CV** (il est alors chiffré dans votre coffre local) ou non.",
        "Cliquez sur **Ajouter au profil**.",
    ])
    g.note("Un CV scanné (image) ou protégé ne contient pas de texte lisible : remplissez alors le profil à la main. "
           "L'option **Analyser avec l'IA** n'apparaît que si l'IA est activée (7.11).", "Limite")

    # 11.3 Search
    g.h2("7.3 Rechercher des opportunités")
    g.p("Décrivez ce que vous cherchez en français ou en anglais, comme vous le diriez à quelqu'un : « bourse de "
        "master en données au Cameroun », « stage marketing à Douala », « appel d'offres informatique 2027 ».")
    g.steps([
        "Ouvrez **Recherche** (Ctrl+2 ou Ctrl+F) et tapez votre demande.",
        "Cliquez sur **Analyser** : Opportunex affiche les **Critères de recherche** qu'il a compris (catégories, "
        "pays, mots-clés…).",
        "Corrigez librement : retirez un critère avec sa croix, ajoutez-en avec **Ajouter**, choisissez un mode de "
        "travail, une date limite maximale, ou incluez les annonces expirées.",
        "Cliquez sur **Lancer la recherche**. La progression s'affiche source par source ; vous pouvez continuer à "
        "utiliser l'application pendant ce temps.",
    ])
    g.figure_("recherche_criteres", "Critères compris et modifiables avant la recherche")
    g.figure_("recherche_resultats", "Résultats d'une recherche")
    g.p("En haut des résultats, la liste **sources à consulter manuellement** donne le lien officiel des portails "
        "qui n'ont pas pu être interrogés automatiquement. Chaque résultat affiche son score, sa catégorie, son "
        "pays, sa date limite (avec le nombre de jours restants), le montant s'il est publié, et des badges : "
        "**Nouvelle**, **Échéance proche**, **Éligibilité incertaine**…")
    g.h3("Trier, filtrer et exporter les résultats")
    g.bullets([
        "Tri : **Pertinence**, **Date limite**, **Publication**, **Montant** ou **Ajout récent**.",
        "Filtre de score : toute pertinence ou score minimal.",
        "Filtre de signalement : nouvelles, échéance proche, etc.",
        "**Exporter** : CSV, XLSX (Excel), PDF ou JSON, enregistré à l'endroit de votre choix.",
    ])
    g.p("L'onglet **Historique** liste vos recherches précédentes : **Voir les résultats**, **Relancer**, "
        "**Comparer avec l'exécution précédente**, ou **Enregistrer la recherche** pour la relancer plus tard ou en "
        "faire une veille.")

    # 11.4 Opportunity sheet
    g.h2("7.4 Fiche d'opportunité")
    g.p("Cliquez sur un résultat pour ouvrir sa fiche : aperçu, date limite, éligibilité, qualifications, pièces à "
        "fournir, avantages financiers, procédure, contact public, éditeur et sources, vérification. Chaque valeur "
        "porte une étiquette d'origine (**Explicite** : écrite dans l'annonce) et, au survol ou en dessous, "
        "l'extrait exact d'où elle provient. Les clauses importantes sont reproduites mot pour mot.")
    g.figure_("fiche_opportunite", "Fiche d'opportunité")
    g.p("La colonne **Pertinence pour vous** détaille le score par critère (compétences, formation, expérience, "
        "localisation, langues, objectifs, date limite), vos atouts et les écarts à vérifier.")
    g.bullets([
        "**Lien officiel** : ouvre l'annonce d'origine dans votre navigateur. C'est là que vous postulez.",
        "**Sauvegarder** / **Voir le suivi** : ajoute l'opportunité à vos candidatures suivies.",
        "Menu ⋮ : **Revérifier sur le site officiel**, ajouter à un espace, marquer comme pertinent ou non "
        "pertinent (ajuste vos recommandations), écarter.",
    ])
    g.note("Lorsque l'annonce ne publie pas de critères d'éligibilité précis, Opportunex l'indique au lieu de "
           "deviner : vérifiez auprès de l'organisme.", "Important")

    # 11.5 Tracking
    g.h2("7.5 Suivre vos candidatures (Sauvegardées)")
    g.p("Chaque opportunité sauvegardée devient une candidature suivie, avec un statut parmi 11 : À examiner, "
        "Découverte, En préparation, Prête à soumettre, Soumise, Entretien, Acceptée, Refusée, Retirée, Expirée, "
        "Archivée. Trois vues sont proposées :")
    g.figure_("suivi_liste", "Vue liste")
    g.figure_("suivi_tableau", "Vue tableau (glisser-déposer entre statuts)")
    g.figure_("suivi_calendrier", "Vue calendrier")
    g.p("Dans le calendrier, **Exporter le calendrier (.ics)** produit un fichier à importer dans Outlook, Google "
        "Agenda ou Thunderbird.")
    g.h3("Détail d'une candidature")
    g.figure_("candidature", "Candidature : statut, événements, notes, documents")
    g.steps([
        "Changez le statut avec les boutons en haut de la page ; l'historique est conservé.",
        "Ajoutez un événement (entretien, relance…) avec sa date : il apparaît au tableau de bord et dans le "
        "calendrier.",
        "Ajoutez des notes, une **Priorité**, des étiquettes, une **Échéance personnelle**, et cochez la **Liste de "
        "contrôle** des pièces à fournir.",
        "**Joindre un fichier** (25 Mo maximum chacun) : les fichiers sont chiffrés dans votre coffre local.",
        "**Ne plus suivre** retire l'opportunité de vos candidatures ; **Archiver** la range sans la supprimer.",
    ])
    g.h3("Brouillons de documents")
    g.p("Depuis une candidature, Opportunex prépare un brouillon : lettre de motivation, lettre de candidature à une "
        "bourse, e-mail de candidature, demande de subvention, résumé de projet, préparation d'entretien, "
        "suggestions d'adaptation du CV. Le brouillon n'utilise que votre profil validé ; un contrôle signale toute "
        "information qui n'en provient pas. Relisez-le, modifiez-le, puis exportez-le en DOCX, PDF ou Markdown.")
    g.h3("Rappels")
    g.p("Des rappels sont envoyés avant chaque date limite : par défaut 14, 7, 3 et 1 jours avant "
        "(Paramètres > Préférences > Rappels avant échéance).")

    # 11.6 Monitors
    g.h2("7.6 Veilles")
    g.p("Une veille relance une recherche à intervalle régulier et vous notifie des nouvelles opportunités au-dessus "
        "d'un score minimal.")
    g.figure_("veilles", "Veilles")
    g.steps([
        "**Veilles** > **Nouvelle veille**.",
        "Donnez un nom, la recherche à surveiller, la fréquence (quotidienne à une heure donnée, ou hebdomadaire) "
        "et le score minimal.",
        "Enregistrez. **Exécuter maintenant** lance une exécution immédiate ; **Historique** montre les exécutions "
        "passées.",
    ])
    g.note("Les veilles ne s'exécutent que lorsque Opportunex est ouvert, y compris réduit dans la zone de "
           "notification. Activez **Lancer Opportunex à l'ouverture de session** (Paramètres > Préférences) pour "
           "qu'elles tournent sans y penser.", "Limite")

    # 11.7 Workspaces
    g.h2("7.7 Espaces de travail")
    g.p("Un espace regroupe des recherches, des opportunités et des notes autour d'un projet (par exemple « Master "
        "2027 »). Vous pouvez partir d'un modèle.")
    g.figure_("espaces", "Liste des espaces")
    g.figure_("espace_detail", "Un espace : recherches, opportunités, notes")
    g.bullets([
        "**Rechercher dans cet espace** : la recherche et ses résultats y sont rattachés.",
        "Ajoutez une opportunité depuis sa fiche (menu ⋮ > Ajouter à un espace).",
        "Cochez plusieurs opportunités puis **Comparer** pour les voir côte à côte.",
        "Archivez ou supprimez un espace depuis son menu.",
    ])

    # 11.8 Sources
    g.h2("7.8 Sources")
    g.p("Le catalogue liste les sources publiques interrogées : organisations internationales, portails de bourses "
        "et d'emploi, marchés publics… Pour chacune : catégories couvertes, fiabilité, dernier succès ou dernière "
        "erreur. Les sources sans flux exploitable ou sans autorisation claire sont proposées en **lien officiel "
        "uniquement**.")
    g.figure_("sources", "Catalogue des sources")
    g.steps([
        "Pour ajouter une source : **Ajouter une source**, collez l'adresse d'une page publique, puis **Détecter et "
        "ajouter**. Opportunex cherche un flux RSS/Atom ou des données structurées.",
        "Pour régler une source : **Fréquence et catégories** (jamais plus d'une fois par heure).",
        "Activez ou désactivez une source avec son interrupteur.",
    ])
    g.p("Opportunex n'interroge que des pages publiques, respecte le fichier robots.txt de chaque site et espace ses "
        "requêtes.")

    # 11.9 Orgs
    g.h2("7.9 Organisations")
    g.p("Une organisation (association, ONG, entreprise, établissement…) permet de partager des espaces et des "
        "opportunités entre plusieurs personnes, chiffrés de bout en bout. Elle nécessite la synchronisation "
        "(7.12).")
    g.figure_("organisations", "Organisations")
    g.figure_("organisation_detail", "Détail d'une organisation : membres, invitations, journal")
    g.steps([
        "**Créer** une organisation (nom, type).",
        "**Inviter** un membre par adresse électronique ou par code, avec un rôle.",
        "Partagez un espace : dans l'espace, **Partager avec une organisation**.",
        "Un membre peut **quitter** l'organisation ; il conserve une copie personnelle des éléments partagés.",
    ])

    # 11.10 Settings
    g.h2("7.10 Paramètres")
    g.h3("Compte et sécurité")
    g.figure_("parametres_compte", "Compte et sécurité")
    g.bullets([
        "**Langue et apparence** : français ou anglais ; thème système, clair ou sombre.",
        "**Verrouillage automatique** : après une inactivité de 15 minutes par défaut (1 à 240 minutes).",
        "**Changer le mot de passe** : vos données restent chiffrées ; seule l'enveloppe de la clé est renouvelée.",
        "**Supprimer le compte** : efface définitivement de cet ordinateur le profil, ses documents et ses "
        "sauvegardes (confirmation par mot de passe et saisie de DELETE).",
    ])
    g.h3("Préférences")
    g.figure_("parametres_preferences", "Préférences")
    g.bullets([
        "Notifications : nouvelles opportunités, opportunité suivie modifiée, rappels d'échéance, source "
        "indisponible, échec d'une veille ; jours de rappel avant échéance.",
        "Réseau : proxy, économiseur de données (ne télécharge pas les pages de détail), volume maximal par "
        "recherche.",
        "Pondération du score : importance de chaque critère.",
        "Suivi et démarrage : réduction dans la zone de notification à la fermeture, archivage automatique des "
        "candidatures closes, lancement à l'ouverture de session.",
    ])
    g.h3("Confidentialité")
    g.figure_("parametres_confidentialite", "Tableau de bord de confidentialité")
    g.bullets([
        "Données stockées (tout est chiffré dans la base locale du profil).",
        "Données envoyées à des tiers : journal de chaque envoi (uniquement si vous avez utilisé une IA en ligne "
        "ou la synchronisation).",
        "Consentements donnés, avec **Retirer** pour les annuler.",
        "Portabilité : **Exporter toutes mes données** (archive ZIP lisible : JSON + fichiers) et **Importer un "
        "export JSON**.",
        "**Effacement sélectif** : supprimez précisément les détails du profil, l'historique des recherches non "
        "enregistrées, les opportunités non sauvegardées, les documents joints, les notifications ou les journaux "
        "(confirmation en saisissant ERASE). Le compte et les candidatures sont conservés.",
        "Aucune télémétrie : Opportunex n'envoie aucune statistique d'utilisation.",
    ])
    g.h3("Maintenance")
    g.figure_("parametres_maintenance", "Maintenance")
    g.bullets([
        "Espace utilisé et **dossier des données**.",
        "**Contrôle d'intégrité** et **Optimiser la base**.",
        "**Journaux techniques** : export expurgé (sans courriel, jeton ni clé) à joindre à un signalement.",
    ])
    g.h3("À propos")
    g.figure_("parametres_a_propos", "À propos : version, éditeur, licence")
    g.p("Cette page affiche la version, l'éditeur, l'auteur, la licence GNU AGPL v3 et la liste des licences "
        "tierces. Les conditions d'utilisation et la politique de confidentialité sont consultables hors ligne :")
    g.figure_("mentions_legales", "Conditions d'utilisation et politique de confidentialité", 13)

    # 11.11 AI
    g.h2("7.11 Assistance par intelligence artificielle (facultative)")
    g.p("Toutes les fonctions marchent sans IA. Si vous l'activez, elle aide à structurer une annonce, résumer, "
        "traduire, interpréter une recherche, analyser un CV ou rédiger un brouillon. Le score de pertinence reste "
        "calculé sans IA.")
    g.figure_("parametres_ia", "Paramètres de l'IA")
    g.steps([
        "Paramètres > IA > **Activer les fonctions d'IA**.",
        "**Ajouter un fournisseur** : Mistral, Gemini, Anthropic, Groq, OpenRouter, un service compatible OpenAI, "
        "ou un modèle local (Ollama, LM Studio).",
        "Collez votre clé d'API (sauf modèle local). Elle est rangée dans le trousseau sécurisé du système, jamais "
        "dans la base ni dans les journaux.",
        "Cliquez sur **Tester** pour vérifier la connexion et choisir un modèle.",
        "Ordonnez les fournisseurs (ordre de repli) et, si besoin, choisissez un fournisseur par tâche.",
    ])
    g.note("Avant le premier envoi à un service en ligne, Opportunex vous demande votre consentement et précise ce "
           "qui sera envoyé. Votre nom, vos coordonnées, vos liens et vos identifiants ne sont jamais envoyés. Avec "
           "un modèle local, aucune donnée ne quitte l'ordinateur. Les valeurs extraites par l'IA sont vérifiées "
           "dans le texte de l'annonce, sinon marquées « Non vérifiable ».", "Important")

    # 11.12 Sync
    g.h2("7.12 Synchronisation chiffrée entre appareils")
    g.p("Facultative, elle copie vos données entre vos ordinateurs via un serveur que vous choisissez. Le chiffrement "
        "est de bout en bout : le serveur ne peut lire ni votre profil, ni vos notes, ni vos candidatures.")
    g.figure_("parametres_synchronisation", "Synchronisation")
    g.steps([
        "Paramètres > Synchronisation : saisissez l'adresse **HTTPS** du serveur (par exemple celui de votre "
        "association), votre adresse et un mot de passe pour le compte en ligne, puis **Créer un compte en ligne**.",
        "Saisissez le **code reçu par e-mail**.",
        "Cliquez sur **Se connecter et lier cet appareil**.",
        "Sur un deuxième ordinateur : liez-le au même compte ; il affiche un **code de couplage**. Sur le premier "
        "appareil, ouvrez **Appareils**, choisissez le nouvel appareil et saisissez ce code pour l'**approuver**.",
    ])
    g.bullets([
        "**Conflits à résoudre** : si un même texte a été modifié sur deux appareils, choisissez la version à garder.",
        "**Double authentification (TOTP)** : un code de votre application d'authentification sera demandé à chaque "
        "nouvelle connexion.",
        "**Mot de passe oublié** (compte en ligne) : rend l'accès au compte, pas aux données ; seuls vos appareils "
        "déjà couplés détiennent les clés.",
        "**Supprimer le compte en ligne** efface vos données du serveur et conserve celles de cet ordinateur.",
    ])
    g.note("Aucune instance officielle n'existe encore : il faut un serveur auto-hébergé (fourni avec le code source, "
           "dossier sync-server). La synchronisation n'a lieu que lorsque l'application est ouverte.", "Limite")


def ch_data(g: Guide) -> None:
    g.h1("8. Créer, consulter, modifier et supprimer vos données")
    g.p("Dans un profil local, vous êtes seul utilisateur et avez tous les droits sur vos données. Le tableau "
        "résume où agir.")
    g.table(
        ["Donnée", "Créer", "Modifier", "Supprimer"],
        [
            ["Profil", "Assistant, Mon profil, import de CV", "Mon profil", "Mon profil (élément par élément)"],
            ["Opportunité suivie", "Sauvegarder (fiche ou résultat)", "Page de la candidature",
             "Ne plus suivre / Archiver"],
            ["Notes, événements, pièces", "Page de la candidature", "Idem", "Idem"],
            ["Brouillon", "Page de la candidature", "Éditeur du brouillon", "Menu du brouillon"],
            ["Veille", "Veilles > Nouvelle veille", "Veilles", "Veilles"],
            ["Espace", "Espaces > Nouvel espace", "Page de l'espace", "Menu de l'espace (archiver, supprimer)"],
            ["Source ajoutée", "Sources > Ajouter une source", "Fréquence et catégories", "Menu de la source"],
            ["Sauvegarde", "Paramètres > Sauvegardes", "—", "Supprimer la sauvegarde"],
            ["Profil complet", "Accueil > Créer un profil", "Paramètres > Compte", "Supprimer le compte"],
        ],
        [3.2, 4.4, 4.2, 4.7],
    )
    g.p("Dans une organisation, les droits dépendent du rôle (chapitre 10). Toute suppression importante demande une "
        "confirmation.")


def ch_search_export(g: Guide) -> None:
    g.h1("9. Recherche, filtres, tri et export")
    g.table(
        ["Besoin", "Où", "Comment"],
        [
            ["Chercher de nouvelles annonces", "Recherche", "Texte libre > Analyser > Lancer la recherche (7.3)"],
            ["Affiner", "Recherche > Critères", "Catégories, pays, mots-clés, mode de travail, date limite, expirées"],
            ["Trier", "Résultats", "Pertinence, date limite, publication, montant, ajout récent"],
            ["Filtrer les résultats", "Résultats", "Score minimal, signalements"],
            ["Retrouver une recherche", "Recherche > Historique", "Rouvrir, relancer, comparer"],
            ["Exporter des résultats", "Résultats > Exporter", "CSV, XLSX, PDF, JSON"],
            ["Exporter le calendrier", "Sauvegardées > Calendrier", "Fichier .ics"],
            ["Exporter un brouillon", "Candidature > Document", "DOCX, PDF, Markdown"],
            ["Exporter toutes vos données", "Paramètres > Confidentialité", "Archive ZIP (JSON + fichiers)"],
        ],
        [4.2, 4.6, 7.7],
    )
    g.p("Les recherches déjà effectuées alimentent aussi une recherche plein texte locale, qui retrouve des "
        "opportunités collectées auparavant même hors connexion.")


def ch_accounts(g: Guide) -> None:
    g.h1("10. Gestion des comptes et des droits")
    g.h2("10.1 Plusieurs profils sur un ordinateur")
    g.p("Chaque personne peut avoir son propre profil, chiffré avec son propre mot de passe. Le sélecteur en bas du "
        "menu permet de changer de profil ou de verrouiller. Un profil ne peut pas lire les données d'un autre.")
    g.h2("10.2 Verrouillage et connexion")
    g.figure_("verrouillage", "Profil verrouillé")
    g.bullets([
        "Ctrl+L verrouille immédiatement ; le verrouillage automatique intervient après l'inactivité réglée.",
        "Après 5 mots de passe erronés, un délai d'attente s'applique : 1 minute, puis il double à chaque nouvel "
        "échec, jusqu'à 60 minutes.",
    ])
    g.h2("10.3 Mot de passe oublié")
    g.steps([
        "Sur l'écran de connexion, cliquez sur **Mot de passe oublié ?**.",
        "Saisissez votre adresse et les 12 mots de votre phrase de récupération.",
        "Choisissez un nouveau mot de passe et cliquez sur **Récupérer et se connecter**.",
    ])
    g.figure_("recuperation", "Récupération du profil avec la phrase de 12 mots")
    g.note("Sans mot de passe ni phrase de récupération, les données sont irrécupérables : c'est la contrepartie du "
           "chiffrement.", "Important")
    g.h2("10.4 Rôles dans une organisation")
    g.table(
        ["Rôle", "Peut"],
        [
            ["Propriétaire", "Tout, y compris gérer les rôles ; une organisation garde au moins un propriétaire"],
            ["Administrateur", "Inviter, retirer des membres, modifier les éléments partagés"],
            ["Éditeur", "Modifier les éléments partagés"],
            ["Lecteur", "Consulter seulement ; une modification locale est annulée"],
        ],
        [3.5, 13],
    )


def ch_files(g: Guide) -> None:
    g.h1("11. Gestion des fichiers")
    g.bullets([
        "**CV importés** : conservés chiffrés dans le coffre local si vous le choisissez, sinon supprimés après "
        "l'analyse.",
        "**Pièces jointes** des candidatures : 25 Mo maximum chacune, chiffrées. Ouvrez-les ou enregistrez-en une "
        "copie depuis la candidature.",
        "**Exports** (CSV, XLSX, PDF, JSON, DOCX, .ics) : enregistrés à l'endroit que vous choisissez, **non "
        "chiffrés** — protégez-les si nécessaire.",
        "**Sauvegardes** : fichiers chiffrés .opxbak (chapitre 12).",
    ])


def ch_backup(g: Guide) -> None:
    g.h1("12. Sauvegarde et restauration")
    g.p("Les sauvegardes sont des archives chiffrées de votre base et de vos documents.")
    g.figure_("parametres_sauvegardes", "Sauvegardes")
    g.bullets([
        "**Automatique** : une fois par jour au plus, quand l'application est ouverte ; les 7 dernières sont "
        "conservées.",
        "**Sauvegarder maintenant** : sauvegarde manuelle.",
        "Sauvegardes de sécurité créées automatiquement avant une mise à jour de la base et avant une restauration.",
        "**Vérifier l'intégrité** d'une sauvegarde à tout moment.",
    ])
    g.h2("Restaurer")
    g.steps([
        "Paramètres > Sauvegardes, choisissez une sauvegarde dans l'historique, puis **Restaurer**.",
        "Confirmez : une sauvegarde de sécurité de l'état actuel est d'abord créée.",
        "La sauvegarde est vérifiée avant de remplacer vos données ; en cas de problème, rien n'est modifié.",
    ])
    g.h2("Sur un autre ordinateur")
    g.p("Copiez un fichier .opxbak (dossier affiché dans Paramètres > Sauvegardes) sur l'autre ordinateur, puis, "
        "sur l'écran d'accueil, choisissez **Importer un profil depuis une sauvegarde**. Le mot de passe du profil "
        "sauvegardé est demandé.")
    g.note("Gardez régulièrement une copie d'une sauvegarde sur un support externe : une sauvegarde rangée sur le "
           "même disque ne protège pas contre la panne de ce disque.", "Conseil")


def ch_errors(g: Guide) -> None:
    g.h1("13. Messages d'erreur courants et solutions")
    g.table(
        ["Message", "Cause", "Solution"],
        [
            ["Adresse ou mot de passe incorrect.", "Erreur de saisie", "Vérifiez le clavier (majuscules) ; sinon "
             "Mot de passe oublié."],
            ["Trop de tentatives échouées. Patientez avant de réessayer.", "5 échecs ou plus",
             "Attendez le délai indiqué (1 à 60 minutes)."],
            ["Mot de passe trop faible…", "Moins de 12 caractères ou mot de passe compromis",
             "Utilisez une phrase de plusieurs mots."],
            ["Un profil utilise déjà cette adresse sur cet ordinateur.", "Profil existant",
             "Connectez-vous à ce profil ou utilisez une autre adresse."],
            ["Phrase de récupération incorrecte.", "Mot manquant ou mal orthographié",
             "Vérifiez les 12 mots et leur ordre."],
            ["Votre session est verrouillée.", "Verrouillage automatique", "Saisissez votre mot de passe."],
            ["Le moteur local ne répond pas. Il redémarre peut-être.", "Moteur redémarré", "Patientez quelques "
             "secondes ; voir chapitre 14 si cela persiste."],
            ["Le profil ne peut pas être déchiffré. Restaurez une sauvegarde.", "Base endommagée",
             "Restaurez la dernière sauvegarde (chapitre 12)."],
            ["Le service externe est indisponible pour le moment.", "Site ou service tiers en panne",
             "Réessayez plus tard ; utilisez le lien officiel."],
            ["Clé d'API refusée par le fournisseur.", "Clé IA invalide ou expirée", "Remplacez la clé dans "
             "Paramètres > IA."],
            ["Quota atteint chez le fournisseur.", "Limite du fournisseur d'IA",
             "Réessayez plus tard ou ajoutez un fournisseur de repli."],
            ["Serveur de synchronisation injoignable…", "Réseau ou serveur", "Vos modifications seront envoyées "
             "plus tard."],
            ["Le serveur doit utiliser HTTPS.", "Adresse en http://", "Utilisez l'adresse https:// du serveur."],
            ["Le code ne correspond pas à l'appareil en attente.", "Erreur de couplage", "Relisez le code affiché "
             "sur le nouvel appareil."],
            ["Invitation invalide, expirée ou déjà utilisée.", "Invitation périmée", "Demandez une nouvelle "
             "invitation."],
        ],
        [5.6, 4.2, 6.7],
    )


def ch_troubleshooting(g: Guide) -> None:
    g.h1("14. Dépannage du démarrage et de la connexion")
    g.p("Opportunex se compose de la fenêtre et d'un **moteur local** démarré automatiquement en arrière-plan. Si "
        "le moteur ne démarre pas, un écran de diagnostic affiche la cause, les détails techniques et les boutons "
        "**Relancer le moteur** et **Ouvrir le dossier des journaux**.")
    g.table(
        ["Symptôme", "Que faire"],
        [
            ["« Opportunex est déjà ouvert pour cet utilisateur »", "Une seule instance est autorisée. Cherchez "
             "l'icône dans la zone de notification (près de l'horloge) > Quitter, puis relancez."],
            ["« Le moteur n'a pas répondu à temps »", "Un antivirus peut bloquer le moteur au premier lancement : "
             "autorisez opportunex-engine.exe, puis Relancer le moteur."],
            ["« Le moteur Opportunex est introuvable »", "Fichiers incomplets : réinstallez. En version portable, "
             "gardez le dossier engine à côté de opportunex.exe."],
            ["« Le moteur s'est arrêté plusieurs fois de suite »", "Exportez les journaux (Maintenance ou "
             "diagnostic) et signalez le problème (chapitre 18)."],
            ["Avertissement SmartScreen à l'installation", "Binaire non signé : vérifiez l'empreinte SHA-256 puis "
             "Exécuter quand même (chapitre 3.1)."],
            ["Aucune source ne répond", "Vérifiez la connexion Internet et le proxy (Paramètres > Préférences > "
             "Réseau). Les portails sans flux s'ouvrent en lien officiel."],
            ["Les veilles ne se déclenchent pas", "L'application doit être ouverte ou réduite dans la zone de "
             "notification ; activez le lancement à l'ouverture de session."],
            ["Aucune notification", "Autorisez les notifications d'Opportunex dans Windows (Paramètres > Système "
             "> Notifications) et dans Paramètres > Préférences."],
        ],
        [5.5, 11],
    )
    g.p("Journaux : %APPDATA%\\PIO\\logs (Windows) ou ~/.local/share/pio/logs (Linux). Utilisez de préférence "
        "l'export expurgé de Paramètres > Maintenance avant de les partager.")


def ch_security(g: Guide) -> None:
    g.h1("15. Sécurité, confidentialité et bonnes pratiques")
    g.h2("Ce qu'Opportunex protège")
    g.bullets([
        "Base de chaque profil chiffrée (SQLCipher, clé de 256 bits protégée par Argon2id) ; documents chiffrés.",
        "Moteur local accessible uniquement depuis votre ordinateur (127.0.0.1), avec un jeton différent à chaque "
        "lancement.",
        "Clés d'API dans le trousseau du système ; aucune télémétrie.",
        "Synchronisation chiffrée de bout en bout ; consentement avant tout envoi à une IA en ligne.",
    ])
    g.h2("Bonnes pratiques")
    g.bullets([
        "Choisissez un mot de passe long et unique ; conservez la phrase de récupération hors de l'ordinateur.",
        "Verrouillez (Ctrl+L) quand vous vous absentez ; gardez un verrouillage automatique court sur un ordinateur "
        "partagé.",
        "Gardez une copie d'une sauvegarde sur un support externe.",
        "Méfiez-vous des annonces qui demandent de l'argent pour postuler : vérifiez toujours sur le site officiel "
        "de l'organisme.",
        "Les exports ne sont pas chiffrés : supprimez-les ou protégez-les après usage.",
        "Ne téléchargez Opportunex que depuis la page officielle du projet et vérifiez l'empreinte SHA-256.",
    ])


def ch_faq(g: Guide) -> None:
    g.h1("16. Questions fréquentes")
    faq = [
        ("Opportunex est-il gratuit ?", "Oui. C'est un logiciel libre sous licence GNU AGPL v3."),
        ("Faut-il une connexion Internet ?", "Seulement pour rechercher de nouvelles annonces, utiliser une IA en "
         "ligne ou synchroniser. Tout le reste fonctionne hors ligne."),
        ("Mes données sont-elles envoyées quelque part ?", "Non, sauf si vous activez vous-même une IA en ligne "
         "(avec consentement) ou la synchronisation (chiffrée de bout en bout). Le journal des envois est dans "
         "Paramètres > Confidentialité."),
        ("Opportunex postule-t-il pour moi ?", "Non. Il prépare et suit ; vous postulez sur le site officiel."),
        ("Pourquoi certaines sources sont-elles « lien officiel uniquement » ?", "Parce qu'elles ne proposent pas "
         "de flux exploitable ou que leurs conditions ne permettent pas une consultation automatique."),
        ("Que signifie « Éligibilité incertaine » ?", "L'annonce ne publie pas de critères précis ; Opportunex "
         "n'affirme jamais une éligibilité qu'il ne peut pas vérifier."),
        ("Comment est calculé le score ?", "Par des règles explicables comparant l'annonce à votre profil : "
         "compétences, formation, expérience, localisation, langues, objectifs, date limite. La pondération se "
         "règle dans Paramètres > Préférences."),
        ("Puis-je utiliser Opportunex sur deux ordinateurs ?", "Oui, avec la synchronisation (serveur "
         "auto-hébergé) ou en transférant une sauvegarde."),
        ("J'ai perdu mot de passe et phrase de récupération.", "Les données ne sont pas récupérables. Vous pouvez "
         "restaurer une sauvegarde si vous en connaissez le mot de passe."),
        ("Existe-t-il une version macOS ?", "Pas dans la version 1.0.0."),
    ]
    for q, a in faq:
        g.p(a, bold_prefix=f"{q} ")


def ch_glossary(g: Guide) -> None:
    g.h1("17. Glossaire")
    g.table(
        ["Terme", "Définition"],
        [
            ["Chiffrement de bout en bout", "Seuls vos appareils peuvent lire les données ; le serveur ne voit que du "
             "contenu chiffré."],
            ["Clé d'API", "Code secret fourni par un service d'IA pour l'utiliser depuis Opportunex."],
            ["Couplage", "Approbation d'un nouvel appareil par un appareil déjà lié, à l'aide d'un code."],
            ["Flux RSS / Atom", "Format standard de publication d'annonces lu automatiquement par Opportunex."],
            ["Lien officiel", "Adresse de l'annonce chez l'organisme qui la publie."],
            ["Moteur local", "Programme d'arrière-plan d'Opportunex qui stocke, recherche et analyse."],
            ["Phrase de récupération", "12 mots permettant de récupérer un profil sans mot de passe."],
            ["Score de pertinence", "Note de 0 à 100 indiquant l'adéquation d'une opportunité à votre profil."],
            ["Source", "Site public consulté lors des recherches."],
            ["TOTP", "Code à 6 chiffres d'une application d'authentification (double authentification)."],
            ["Veille", "Recherche relancée automatiquement à intervalle régulier."],
            ["Zone de notification", "Zone de la barre des tâches près de l'horloge où Opportunex peut rester actif."],
        ],
        [4.5, 12],
    )


def ch_support(g: Guide) -> None:
    g.h1("18. Assistance, signalement des bugs et coordonnées officielles")
    g.bullets([
        "Projet et téléchargements : https://github.com/momogodi2000/OpportuNex",
        "Signaler un bug ou proposer une amélioration : https://github.com/momogodi2000/OpportuNex/issues",
        "Signaler une faille de sécurité : uniquement par le signalement privé de GitHub (onglet Security du "
        "projet), jamais dans un ticket public — voir SECURITY.md.",
    ])
    g.h2("Bien signaler un problème")
    g.steps([
        "Indiquez la version (Paramètres > À propos) et votre système (Windows 10, 11, Ubuntu…).",
        "Décrivez les étapes pour reproduire, ce que vous attendiez et ce qui s'est passé.",
        "Joignez les journaux expurgés (Paramètres > Maintenance > Journaux techniques > Exporter).",
        "Ne joignez jamais votre phrase de récupération, votre mot de passe ni une clé d'API.",
    ])
    g.p("Éditeur : ETS Monthe Network. Auteur principal : Momo Godi Yvan.")


def ch_annexes(g: Guide) -> None:
    g.h1("19. Annexes")
    g.h2("A. Catégories d'opportunités")
    g.p("Appels à candidatures · Appels d'offres · Autres opportunités · Bourses · Concours et prix · Emploi · "
        "Entrepreneuriat · Formations · Incubation et accélération · Missions freelance · Partenariats · Recherche · "
        "Stages · Subventions et financements · Volontariat.")
    g.h2("B. Statuts de candidature")
    g.p("À examiner · Découverte · En préparation · Prête à soumettre · Soumise · Entretien · Acceptée · Refusée · "
        "Retirée · Expirée · Archivée.")
    g.h2("C. Emplacement des données")
    g.table(
        ["Système", "Dossier"],
        [["Windows", "%APPDATA%\\PIO"], ["Linux", "~/.local/share/pio (ou $XDG_DATA_HOME/pio)"]],
        [4, 12.5],
    )
    g.h2("D. Formats de fichiers")
    g.table(
        ["Format", "Usage"],
        [
            ["PDF, DOCX, TXT", "Import de CV"],
            ["CSV, XLSX, PDF, JSON", "Export des résultats"],
            ["DOCX, PDF, Markdown", "Export des brouillons"],
            [".ics", "Export du calendrier"],
            ["ZIP (JSON + fichiers)", "Export complet de vos données"],
            [".opxbak", "Sauvegarde chiffrée"],
        ],
        [5, 11.5],
    )
    g.h2("E. Enregistrements vidéo")
    g.p("Aucune vidéo n'accompagne cette édition. Le script documentation/user-guide/tools/record_video.ps1 permet "
        "d'enregistrer les parcours essentiels de l'application réelle lorsque l'outil ffmpeg est installé ; les "
        "vidéos produites sont rangées dans documentation/user-guide/videos/.")


def fix_metadata() -> None:
    """After Word has saved the file (finalize_with_word.ps1): author fields name the guide's author, not the
    Office account that ran Word."""
    doc = Document(str(OUT))
    doc.core_properties.last_modified_by = "Momo Godi Yvan"
    doc.save(OUT)


def main() -> None:
    if "--metadata-only" in sys.argv:
        fix_metadata()
        return
    collect_screenshots()
    annotate_dashboard()
    g = Guide()
    cover(g)
    g.header_footer()
    front_matter(g)
    ch_presentation(g)
    ch_requirements(g)
    ch_windows(g)
    ch_linux(g)
    ch_first_launch(g)
    ch_interface(g)
    ch_modules(g)
    ch_data(g)
    ch_search_export(g)
    ch_accounts(g)
    ch_files(g)
    ch_backup(g)
    ch_errors(g)
    ch_troubleshooting(g)
    ch_security(g)
    ch_faq(g)
    ch_glossary(g)
    ch_support(g)
    ch_annexes(g)
    g.save()
    print(f"{OUT.relative_to(ROOT)}: {g.figure} figures")


if __name__ == "__main__":
    main()
