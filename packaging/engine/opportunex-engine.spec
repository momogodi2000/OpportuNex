# PyInstaller spec for the Opportunex engine — one-folder build (decision D-13).
#
#   engine/.venv/Scripts/python -m PyInstaller packaging/engine/opportunex-engine.spec \
#       --distpath build/engine --workpath build/engine-work --noconfirm
#
# Output: build/engine/opportunex-engine/opportunex-engine(.exe) plus its _internal/ folder.
# The desktop app looks for it at <app folder>/engine/opportunex-engine(.exe).
# ruff: noqa
import sys
from pathlib import Path

from PyInstaller.utils.hooks import collect_all, collect_data_files, collect_submodules

ROOT = Path(SPECPATH).resolve().parents[1]  # noqa: F821 - provided by PyInstaller
ENGINE = ROOT / "engine"

# Read-only resources located through core.config.resource_dir().
datas = [
    (str(ENGINE / "connectors" / "catalog.json"), "connectors"),
    (str(ENGINE / "connectors" / "verification.json"), "connectors"),
    (str(ENGINE / "persistence" / "schema" / "pio_schema.sql"), "persistence/schema"),
    (str(ENGINE / "persistence" / "migrations" / "env.py"), "persistence/migrations"),
    (str(ENGINE / "persistence" / "migrations" / "script.py.mako"), "persistence/migrations"),
    (str(ENGINE / "security" / "compromised_passwords.txt"), "security"),
    (str(ENGINE / "security" / "wordlists"), "security/wordlists"),
]
# Alembic loads migration scripts from files, so they ship as source.
datas += [(str(p), "persistence/migrations/versions") for p in (ENGINE / "persistence" / "migrations" / "versions").glob("*.py")]

binaries = []
hiddenimports = [
    "sqlcipher3",
    "sqlalchemy.dialects.sqlite.pysqlcipher",
    "uvicorn.logging",
    "uvicorn.loops.auto",
    "uvicorn.loops.asyncio",
    "uvicorn.protocols.http.auto",
    "uvicorn.protocols.http.h11_impl",
    "uvicorn.protocols.websockets.auto",
    "uvicorn.protocols.websockets.websockets_impl",
    "uvicorn.lifespan.on",
    "email_validator",
    "multipart",
    "nacl.bindings",
    "keyring.backends",
]
hiddenimports += collect_submodules("keyring.backends")
hiddenimports += collect_submodules("alembic")
hiddenimports += collect_submodules("api") + collect_submodules("services") + collect_submodules("sync")

# Packages carrying data files or plug-in style imports.
for pkg in ("trafilatura", "justext", "courlan", "htmldate", "dateparser", "tld", "certifi", "extruct",
            "reportlab", "langdetect", "zxcvbn", "pdfplumber", "pdfminer", "docx", "openpyxl", "selectolax",
            "rapidfuzz", "feedparser", "protego",
            # extruct's own parsers (loaded on demand, invisible to the import analysis)
            "w3lib", "mf2py", "pyrdfa", "rdflib", "html_text", "jstyleson", "lxml", "lxml_html_clean"):
    try:
        d, b, h = collect_all(pkg)
    except Exception:  # package absent in this environment
        continue
    datas += d
    binaries += b
    hiddenimports += h

a = Analysis(  # noqa: F821
    [str(ENGINE / "main.py")],
    pathex=[str(ENGINE)],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    excludes=["tkinter", "pytest", "mypy", "ruff", "IPython", "matplotlib", "PyQt5", "PySide6", "_legacy", "tests"],
    noarchive=False,
)
pyz = PYZ(a.pure)  # noqa: F821
exe = EXE(  # noqa: F821
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="opportunex-engine",
    console=True,  # stdin/stdout carry the token handshake with the desktop supervisor
    icon=str(ROOT / "apps" / "desktop" / "windows" / "runner" / "resources" / "app_icon.ico") if sys.platform == "win32" else None,
    version=str(ROOT / "packaging" / "engine" / "version_info.txt") if sys.platform == "win32" else None,
)
coll = COLLECT(exe, a.binaries, a.datas, strip=False, upx=False, name="opportunex-engine")  # noqa: F821
