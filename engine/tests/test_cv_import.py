from __future__ import annotations

import io

import pytest

from core.errors import ValidationFailed
from documents import cv_parser
from tests.conftest import EngineClient

CV_TEXT = """AWA NDJOCK
Douala, Cameroun — awa@example.com — https://www.linkedin.com/in/awa-ndjock

FORMATION
Master en Statistique appliquée - Université de Yaoundé II
2019 - 2021
Licence en Mathématiques - Université de Douala
2016 - 2019

EXPÉRIENCE PROFESSIONNELLE
Analyste de données - ONG Santé Plus
sept. 2021 - aujourd'hui
Collecte et analyse de données de santé avec Python et SQL.
Stagiaire en statistique - Institut National de la Statistique
2020 - 2021

COMPÉTENCES
Python, SQL, Power BI, Kobotoolbox, gestion de projet

LANGUES
Français : langue maternelle
Anglais : courant (C1)
"""


def _docx_bytes(text: str) -> bytes:
    import docx

    d = docx.Document()
    for line in text.splitlines():
        d.add_paragraph(line)
    buf = io.BytesIO()
    d.save(buf)
    return buf.getvalue()


def _pdf_bytes(text: str) -> bytes:
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfgen import canvas

    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    y = 800
    for line in text.splitlines():
        c.drawString(40, y, line)
        y -= 14
    c.save()
    return buf.getvalue()


def test_type_detection_checks_content_not_just_extension() -> None:
    assert cv_parser.detect_mime("cv.pdf", b"%PDF-1.7 ...") == cv_parser.PDF
    with pytest.raises(ValidationFailed) as e:
        cv_parser.detect_mime("cv.pdf", b"MZ\x90 executable")
    assert e.value.code == "file_type_mismatch"
    with pytest.raises(ValidationFailed) as e:
        cv_parser.detect_mime("cv.exe", b"x")
    assert e.value.code == "file_type_unsupported"
    with pytest.raises(ValidationFailed) as e:
        cv_parser.detect_mime("cv.txt", b"x" * (cv_parser.MAX_BYTES + 1))
    assert e.value.code == "file_too_large"


def test_macro_enabled_docx_is_refused() -> None:
    import zipfile

    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        zf.writestr("word/document.xml", "<w/>")
        zf.writestr("word/vbaProject.bin", b"macro")
    with pytest.raises(ValidationFailed) as e:
        cv_parser.detect_mime("cv.docx", buf.getvalue())
    assert e.value.code == "file_active_content"


def test_deterministic_extraction_from_text() -> None:
    known = {"python": "Python", "sql": "SQL", "power bi": "Power BI", "gestion de projet": "Gestion de projet"}
    out = cv_parser.extract_items(CV_TEXT, known)
    by_type: dict[str, list[dict[str, object]]] = {}
    for item in out.items:
        by_type.setdefault(item.item_type, []).append(item.payload)
    assert by_type["identity"][0]["full_name"] == "Awa Ndjock"
    edu = by_type["education"]
    assert edu[0]["institution"] == "Université de Yaoundé II" and edu[0]["start_date"] == "2019"
    exp = by_type["experience"]
    assert exp[0]["job_title"] == "Analyste de données" and exp[0]["employer"] == "ONG Santé Plus"
    assert exp[0]["start_date"] == "2021-09" and exp[0]["is_current"] is True
    skills = {s["name"] for s in by_type["skill"]}
    assert {"Python", "SQL", "Power BI", "Gestion de projet", "Kobotoolbox"} <= skills
    langs = {(x["language_code"], x["cefr_level"]) for x in by_type["language"]}
    assert langs == {("fr", "native"), ("en", "C2")} or langs == {("fr", "native"), ("en", "C1")}
    assert by_type["link"][0]["kind"] == "linkedin"


@pytest.mark.parametrize(
    "name,maker", [("cv.docx", _docx_bytes), ("cv.pdf", _pdf_bytes), ("cv.txt", lambda t: t.encode("utf-8"))]
)
def test_upload_review_apply_flow(signed_in: EngineClient, name: str, maker: object) -> None:
    data = maker(CV_TEXT)  # type: ignore[operator]
    r = signed_in.post("/cv-imports", files={"file": (name, data)}, data={"keep_file": "true"})
    assert r.status_code == 201, r.text
    imp = r.json()
    assert imp["status"] == "review" and imp["file_kept"] is True
    items = imp["items"]
    assert any(i["item_type"] == "experience" for i in items)
    # Nothing reaches the profile before validation (EF-03.04).
    assert signed_in.get("/profile").json()["experiences"] == []
    for item in items:
        decision = "accepted" if item["item_type"] in ("experience", "skill", "education") else "rejected"
        signed_in.put(f"/cv-imports/{imp['id']}/items/{item['id']}", json={"decision": decision})
    applied = signed_in.post(f"/cv-imports/{imp['id']}/apply").json()
    assert applied["applied"] >= 3
    profile = applied["profile"]
    assert {e["employer"] for e in profile["experiences"]} >= {"ONG Santé Plus"}
    assert all(e["source"] == "cv_import" for e in profile["experiences"])
    assert profile["languages"] == []  # rejected items are not applied
    assert signed_in.post(f"/cv-imports/{imp['id']}/apply").status_code == 409
    assert signed_in.delete(f"/cv-imports/{imp['id']}/file").status_code == 204
    assert signed_in.get(f"/cv-imports/{imp['id']}").json()["file_kept"] is False


def test_edited_item_and_discard(signed_in: EngineClient) -> None:
    imp = signed_in.post("/cv-imports", files={"file": ("cv.txt", CV_TEXT.encode())}).json()
    assert imp["file_kept"] is False
    skill = next(i for i in imp["items"] if i["item_type"] == "skill")
    edited = signed_in.put(
        f"/cv-imports/{imp['id']}/items/{skill['id']}",
        json={"decision": "accepted", "payload": {"name": "Statistiques"}},
    ).json()
    assert next(i for i in edited["items"] if i["id"] == skill["id"])["decision"] == "edited"
    signed_in.post(f"/cv-imports/{imp['id']}/apply")
    assert "Statistiques" in [s["name"] for s in signed_in.get("/profile").json()["skills"]]
    imp2 = signed_in.post("/cv-imports", files={"file": ("cv.txt", CV_TEXT.encode())}).json()
    assert signed_in.delete(f"/cv-imports/{imp2['id']}").status_code == 204
    assert signed_in.get(f"/cv-imports/{imp2['id']}").status_code == 404


def test_malformed_pdf_is_reported_not_crashing(signed_in: EngineClient) -> None:
    r = signed_in.post("/cv-imports", files={"file": ("cv.pdf", b"%PDF-1.4\n garbage without objects")})
    assert r.status_code == 422
    assert r.json()["code"] in ("file_malformed", "file_parse_timeout")
    items = signed_in.get("/cv-imports").json()["items"]
    assert items[0]["status"] == "failed"
