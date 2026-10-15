"""Generate application icons from the brand sheet (documentation/cahier_de_charge/opportunex.png).

The brand sheet contains the official desktop app tile (bottom-left). This script crops it,
applies the rounded-square mask and writes every size the platforms need:

* apps/desktop/assets/images/app_icon.png        (256 px, used inside the UI)
* apps/desktop/windows/runner/resources/app_icon.ico (16..256 px)
* packaging/branding/icons/hicolor/<n>x<n>/apps/opportunex.png (Linux)
* packaging/branding/app_icon_512.png            (master)

Run with any Python that has Pillow:  python packaging/branding/make_icons.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SHEET = ROOT / "documentation" / "cahier_de_charge" / "opportunex.png"
TILE_REGION = (60, 785, 350, 1075)  # around the "Icône de l'application" tile
LINUX_SIZES = (16, 24, 32, 48, 64, 128, 256, 512)


def master(size: int = 512) -> Image.Image:
    sheet = Image.open(SHEET).convert("RGB")
    crop = sheet.crop(TILE_REGION)
    bg = Image.new("RGB", crop.size, crop.getpixel((2, 2)))
    diff = ImageChops.difference(crop, bg).convert("L").point(lambda v: 255 if v > 40 else 0)
    box = diff.getbbox()
    if box is None:
        raise SystemExit("app tile not found in brand sheet")
    tile = crop.crop(box)
    w, h = tile.size
    s = min(w, h)
    tile = tile.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))
    img = tile.resize((size, size), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size * 4 - 1, size * 4 - 1), radius=int(size * 4 * 0.22), fill=255)
    img.putalpha(mask.resize((size, size), Image.LANCZOS))
    return img


def main() -> None:
    img = master()
    out = ROOT / "packaging" / "branding"
    img.save(out / "app_icon_512.png")
    img.resize((256, 256), Image.LANCZOS).save(ROOT / "apps" / "desktop" / "assets" / "images" / "app_icon.png")
    img.save(ROOT / "apps" / "desktop" / "windows" / "runner" / "resources" / "app_icon.ico",
             sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    for n in LINUX_SIZES:
        target = out / "icons" / "hicolor" / f"{n}x{n}" / "apps" / "opportunex.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        img.resize((n, n), Image.LANCZOS).save(target)
    print("icons written")


if __name__ == "__main__":
    main()
