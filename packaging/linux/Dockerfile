# Reproducible builder for the Opportunex Debian package (Ubuntu 24.04, Python 3.12, Flutter 3.41.2).
#   docker build -t opportunex-linux-builder packaging/linux
#   docker run --rm -v "$PWD:/src" opportunex-linux-builder bash packaging/linux/build-deb.sh
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive TZ=UTC LANG=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git unzip xz-utils zip file \
        clang cmake ninja-build pkg-config build-essential \
        libgtk-3-dev liblzma-dev libstdc++-12-dev \
        libayatana-appindicator3-dev libnotify-dev libsecret-1-dev \
        python3.12 python3.12-venv python3.12-dev \
        dpkg-dev fakeroot \
    && rm -rf /var/lib/apt/lists/*

ARG FLUTTER_VERSION=3.41.2
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        | tar -xJ -C /opt \
    && git config --global --add safe.directory /opt/flutter \
    && git config --global --add safe.directory /src
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics --enable-linux-desktop && flutter precache --linux

WORKDIR /src
