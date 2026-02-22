#!/usr/bin/env bash

THIS_DIR="$(dirname "$(readlink -f -- "$0")")"
source "${THIS_DIR}/../toolbox/stable-version.sh"

sudo dnf install --setopt=install_weak_deps=False --assumeyes \
  'cmake' \
  'clang' \
  'clang-tools-extra' \
  'cli11-devel' \
  'dbus-devel' \
  'git' \
  'jemalloc-devel' \
  'libdrm-devel' \
  'libxkbcommon-devel' \
  'mesa-libgbm-devel' \
  'ninja-build' \
  'pam-devel' \
  'pipewire-devel' \
  'pkg-config' \
  'qt6-qtbase-devel' \
  'qt6-qtbase-private-devel' \
  'qt6-qtdeclarative-devel' \
  'qt6-qtdeclarative-private-devel' \
  'qt6-qtshadertools-devel' \
  'qt6-qtsvg-devel' \
  'qt6-qtwayland-devel' \
  'systemd-devel' \
  'wayland-devel' \
  'wayland-protocols-devel'

[ -d '/tmp/quickshell' ] || git clone 'https://git.outfoxxed.me/quickshell/quickshell.git' '/tmp/quickshell'
TAG="$(local_stable_version '/tmp/quickshell')"
git -C '/tmp/quickshell' switch --detach "${TAG}"

# It's easier to compile in support for Hyprland and i3, than to
# remove references to them in Noctalia.
cmake \
    -S '/tmp/quickshell' \
    -B '/tmp/quickshell/build' \
    -G 'Ninja' \
    -D'CMAKE_BUILD_TYPE=Release' \
    -D'CMAKE_C_COMPILER=clang' \
    -D'CMAKE_CXX_COMPILER=clang++' \
    -D"CMAKE_INSTALL_PREFIX=${HOME}/.local" \
    -D'DISTRIBUTOR=Zan Baldwin' \
    -D'HYPRLAND=ON' \
    -D'I3=ON' \
    -D'X11=OFF' \
    -D'CRASH_REPORTER=OFF'

cmake --build '/tmp/quickshell/build' -j"$(nproc)"
cmake --install '/tmp/quickshell/build'
