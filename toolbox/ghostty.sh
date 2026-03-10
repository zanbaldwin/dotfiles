#!/usr/bin/env bash

export ZIG_VERSION="0.15.2"
export GHOSTTY_VERSION="1.3.0"
export BUILD_DIR="/tmp/ghostty-build"

mkdir -p "${BUILD_DIR}"
curl -fsSL "https://ziglang.org/download/${ZIG_VERSION}/zig-$(uname -m)-linux-${ZIG_VERSION}.tar.xz" -o "${BUILD_DIR}/zig.tar.xz"
curl -fsSL "https://release.files.ghostty.org/${GHOSTTY_VERSION}/ghostty-${GHOSTTY_VERSION}.tar.gz" -o "${BUILD_DIR}/ghostty.tar.gz"
tar vxJf "${BUILD_DIR}/zig.tar.xz"
tar vxzf "${BUILD_DIR}/ghostty.tar.gz"

sudo dnf install --assumeyes \
    'gettext-devel' \
    'gtk4-devel' \
    'gtk4-layer-shell-devel' \
    'libadwaita-devel' \
    'pkgconf-pkg-config' \
    'tar' \
    'xz'

(cd "${BUILD_DIR}/ghostty-${GHOSTTY_VERSION}"; "${BUILD_DIR}/zig-$(uname -m)-linux-${ZIG_VERSION}/zig" build -Doptimize=ReleaseFast)
mkdir -p "${HOME}/bin"
mv "${BUILD_DIR}/ghostty-${GHOSTTY_VERSION}/zig-out/bin/ghostty" "${HOME}/bin"
