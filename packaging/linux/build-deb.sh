#!/usr/bin/env bash
# Build dist/linux/opportunex_<version>_amd64.deb inside the builder image (packaging/linux/Dockerfile).
# Layout: /opt/opportunex (Flutter bundle + engine/ + licenses/), launcher /usr/bin/opportunex,
# desktop entry and hicolor icons. Data stays in ~/.local/share/pio (decision D-27).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' "$ROOT/apps/desktop/pubspec.yaml")"
WORK="$ROOT/build/linux-deb"
PKG="$WORK/opportunex_${VERSION}_amd64"
OUT="$ROOT/dist/linux"
echo "Opportunex $VERSION — Debian package"

# 1. Engine (PyInstaller, built here so it links against this distribution's libraries).
python3.12 -m venv "$WORK/venv"
"$WORK/venv/bin/pip" install --quiet --upgrade pip
"$WORK/venv/bin/pip" install --quiet -r "$ROOT/engine/requirements.txt" "pyinstaller>=6.11"
"$WORK/venv/bin/python" -m PyInstaller "$ROOT/packaging/engine/opportunex-engine.spec" \
    --distpath "$WORK/engine" --workpath "$WORK/engine-work" --noconfirm --log-level ERROR
OPX_DATA_DIR="$(mktemp -d)" "$WORK/engine/opportunex-engine/opportunex-engine" --self-test

# 2. Desktop.
(cd "$ROOT/apps/desktop" && flutter pub get && flutter build linux --release)

# 3. Package tree.
rm -rf "$PKG" && mkdir -p "$PKG/DEBIAN" "$PKG/opt/opportunex" "$PKG/usr/bin" "$PKG/usr/share/applications"
cp -a "$ROOT/apps/desktop/build/linux/x64/release/bundle/." "$PKG/opt/opportunex/"
mkdir -p "$PKG/opt/opportunex/engine" "$PKG/opt/opportunex/licenses"
cp -a "$WORK/engine/opportunex-engine/." "$PKG/opt/opportunex/engine/"
cp "$ROOT"/{LICENSE,NOTICE,THIRD_PARTY_NOTICES.md,TRADEMARKS.md,CHANGELOG.md} "$PKG/opt/opportunex/licenses/"
cp -a "$ROOT/packaging/licenses/." "$PKG/opt/opportunex/licenses/"
ln -s /opt/opportunex/opportunex "$PKG/usr/bin/opportunex"
for size in 16 24 32 48 64 128 256 512; do
    install -Dm644 "$ROOT/packaging/branding/icons/hicolor/${size}x${size}/apps/opportunex.png" \
        "$PKG/usr/share/icons/hicolor/${size}x${size}/apps/opportunex.png"
done
cat > "$PKG/usr/share/applications/app.opportunex.Opportunex.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Opportunex
GenericName=Opportunities intelligence
GenericName[fr]=Veille d'opportunités
Comment=Find, analyse and track opportunities — local first, open source
Comment[fr]=Trouvez, analysez et suivez des opportunités — local d'abord, libre
Exec=/opt/opportunex/opportunex
Icon=opportunex
Categories=Office;Education;
StartupWMClass=app.opportunex.Opportunex
Terminal=false
EOF

INSTALLED_KB="$(du -sk "$PKG/opt" "$PKG/usr" | awk '{s+=$1} END {print s}')"
cat > "$PKG/DEBIAN/control" <<EOF
Package: opportunex
Version: $VERSION
Section: misc
Priority: optional
Architecture: amd64
Installed-Size: $INSTALLED_KB
Depends: libgtk-3-0t64 | libgtk-3-0, libayatana-appindicator3-1, libnotify4, libsecret-1-0, libstdc++6, libgcc-s1, zlib1g
Recommends: gnome-keyring | kwalletmanager
Maintainer: ETS Monthe Network <https://github.com/momogodi2000/OpportuNex>
Homepage: https://github.com/momogodi2000/OpportuNex
Description: Opportunities intelligence platform (local first, open source)
 Opportunex finds, analyses and tracks scholarships, jobs, grants and tenders.
 Data stays on this computer in an encrypted database; AI and encrypted
 sync are optional. Licence: GNU AGPL v3.
EOF
cat > "$PKG/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q /usr/share/icons/hicolor || true
command -v update-desktop-database >/dev/null && update-desktop-database -q /usr/share/applications || true
exit 0
EOF
cat > "$PKG/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
# User data in ~/.local/share/pio is never removed by the package manager.
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q /usr/share/icons/hicolor || true
command -v update-desktop-database >/dev/null && update-desktop-database -q /usr/share/applications || true
exit 0
EOF
chmod 0755 "$PKG/DEBIAN/postinst" "$PKG/DEBIAN/postrm"

mkdir -p "$OUT"
dpkg-deb --build --root-owner-group "$PKG" "$OUT/opportunex_${VERSION}_amd64.deb"
(cd "$OUT" && sha256sum ./*.deb > SHA256SUMS.txt)
echo "Done: $OUT/opportunex_${VERSION}_amd64.deb"
