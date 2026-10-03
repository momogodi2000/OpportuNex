#!/bin/bash
set -e

echo "Building OpportuNex Linux .deb package..."

# Build the flutter app
cd apps/desktop
flutter pub get
flutter build linux --release

# We also need to package the Python engine
cd ../../engine
# Create a venv for the engine (in production it should be a standalone executable or bundled venv)
python3 -m venv dist-venv
source dist-venv/bin/activate
pip install -r requirements.txt
pip install -e .
deactivate

# Combine them into a .deb package
cd ..
mkdir -p build/deb/opt/opportunex/engine
mkdir -p build/deb/opt/opportunex/desktop
mkdir -p build/deb/usr/share/applications
mkdir -p build/deb/usr/bin
mkdir -p build/deb/DEBIAN

# Copy Flutter build
cp -r apps/desktop/build/linux/x64/release/bundle/* build/deb/opt/opportunex/desktop/

# Copy Engine build
cp -r engine/* build/deb/opt/opportunex/engine/
cp -r engine/dist-venv build/deb/opt/opportunex/engine/

# Create desktop file
cat <<EOF > build/deb/usr/share/applications/opportunex.desktop
[Desktop Entry]
Version=1.0
Name=OpportuNex
Comment=OpportuNex - Intelligence des Opportunités
Exec=/opt/opportunex/desktop/opportunex
Icon=/opt/opportunex/desktop/data/flutter_assets/assets/icon.png
Terminal=false
Type=Application
Categories=Utility;
EOF

# Create postinst script to ensure permissions
cat <<EOF > build/deb/DEBIAN/postinst
#!/bin/bash
chmod 755 /opt/opportunex/desktop/opportunex
EOF
chmod 755 build/deb/DEBIAN/postinst

# Create control file
cat <<EOF > build/deb/DEBIAN/control
Package: opportunex
Version: 0.1.0
Architecture: amd64
Maintainer: ING Momo Godi Yvan <contact@protegeqv.org>
Description: OpportuNex — Intelligence des Opportunités
EOF

# Build the .deb
dpkg-deb --build build/deb opportunex-linux-amd64.deb

echo "Build complete: opportunex-linux-amd64.deb"
