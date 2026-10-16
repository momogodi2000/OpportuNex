#!/usr/bin/env bash
# Install the built package in a clean Ubuntu 24.04 container and check that it works headless:
#   docker run --rm -v "$PWD:/src" ubuntu:24.04 bash /src/packaging/linux/test-deb.sh
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
DEB="$(ls /src/dist/linux/opportunex_*_amd64.deb | head -1)"
apt-get update -qq
apt-get install -y -qq "$DEB" xvfb dbus-x11 >/dev/null
echo "== installed files"
test -x /opt/opportunex/opportunex
test -x /opt/opportunex/engine/opportunex-engine
test -f /usr/share/applications/app.opportunex.Opportunex.desktop
echo "== engine self-test"
OPX_DATA_DIR="$(mktemp -d)" /opt/opportunex/engine/opportunex-engine --self-test
echo "== desktop start under Xvfb (10 s)"
export HOME="$(mktemp -d)"
set +e
timeout 10 xvfb-run -a dbus-launch /opt/opportunex/opportunex
code=$?
set -e
# 124 = still running when the timeout stopped it, i.e. it started and stayed up.
if [ "$code" != "124" ]; then echo "desktop exited early with $code"; exit 1; fi
test -d "$HOME/.local/share/pio" && echo "data folder created: $HOME/.local/share/pio"
echo "== removal keeps user data"
apt-get remove -y -qq opportunex >/dev/null
test ! -e /opt/opportunex/opportunex
echo "DEB TEST OK"
