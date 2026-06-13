#!/usr/bin/env bash

if [ ! -f '/run/.toolboxenv' ]; then
    echo 'error: not inside a toolbox; refusing to modify system packages outside a toolbox.' >&2
    exit 1
fi

# Rust/Cargo is provisioned early on new machines, so fail fast if it's missing.
[ -f "${HOME}/.cargo/env" ] && source "${HOME}/.cargo/env"
command -v cargo >'/dev/null' 2>&1 || {
    echo 'error: cargo (Rust toolchain) not found; install Rust/Cargo first.' >&2
    exit 1
}

sudo dnf install --setopt=install_weak_deps=False --assumeyes \
  'cairo-devel' \
  'clang' \
  'cmake' \
  'fontconfig-devel' \
  'freetype-devel' \
  'gcc-c++' \
  'git' \
  'glib2-devel' \
  'jemalloc-devel' \
  'libcurl-devel' \
  'libEGL-devel' \
  'libqalculate-devel' \
  'librsvg2-devel' \
  'libwebp-devel' \
  'libxkbcommon-devel' \
  'mesa-libGLES-devel' \
  'meson' \
  'ninja-build' \
  'pam-devel' \
  'pango-devel' \
  'pipewire-devel' \
  'polkit-devel' \
  'sdbus-cpp-devel' \
  'wayland-devel' \
  'wayland-protocols-devel'

# `just` is installed via Cargo to match the rest of my Rust-based tooling.
command -v just >'/dev/null' 2>&1 || cargo install --locked 'just'

# Noctalia v5 is in alpha; the packaged form is `noctalia-git`, so build from
# the default branch rather than pinning a stable tag.
[ -d '/tmp/noctalia' ] || git clone --depth=1 'https://github.com/noctalia-dev/noctalia.git' '/tmp/noctalia'
git -C '/tmp/noctalia' pull --ff-only

# Meson reads these on first `meson setup`; the justfile shells out to meson, so
# exporting here is enough (no justfile patching needed).
# Raise the microarchitecture baseline to x86-64-v3 (AVX2/BMI/FMA-era CPUs).
export CFLAGS="${CFLAGS:-} -march=x86-64-v3"
export CXXFLAGS="${CXXFLAGS:-} -march=x86-64-v3"
# gcc is upstream's documented Fedora toolchain. To experiment with clang,
# run with CC=clang CXX=clang++ (the `clang` package is installed above).
export CC="${CC:-gcc}"
export CXX="${CXX:-g++}"

cd '/tmp/noctalia' || exit 1

# Drop the build cache so each run reconfigures from scratch: this both forces a
# full recompile and ensures the CC/CXX/CFLAGS changes above actually take effect
# (meson bakes them in at first setup and ignores them on a reused build dir).
rm -rf 'build-release'
rm -f "${HOME}/.local/bin/noctalia"

just configure release "${HOME}/.local"
just build release
just install release
