#!/usr/bin/env bash
THIS_DIR="$(dirname "$(readlink -f -- "$0")")"

# Niri
sudo dnf install --setopt=install_weak_deps=False --assumeyes 'niri'

# Kanshi
sudo dnf install --setopt=install_weak_deps=False --assumeyes 'kanshi'

# Kanata
cargo install --locked 'kanata'
sudo groupdel 'uinput' 2>'/dev/null'
sudo groupadd --system 'uinput'
sudo usermod -aG 'input' "${USER}"
sudo usermod -aG 'uinput' "${USER}"
sudo tee '/etc/udev/rules.d/99-uinput.rules' >'/dev/null' <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF
sudo tee '/etc/modules-load.d/uinput.conf' >'/dev/null' <<'EOF'
uinput
EOF
sudo udevadm control --reload-rules && sudo udevadm trigger
systemctl --user enable 'kanata.service'

# Noctalia runtime libraries: the toolbox build links against the -devel
# counterparts, but the shell runs on the host, so the shared libraries must be
# present here too (niri does not pull the GUI stack in on its own).
sudo dnf install --setopt=install_weak_deps=False --assumeyes \
    'cairo' \
    'fontconfig' \
    'freetype' \
    'glib2' \
    'harfbuzz' \
    'jemalloc' \
    'libcurl' \
    'libglvnd-egl' \
    'libglvnd-gles' \
    'libqalculate' \
    'librsvg2' \
    'libwayland-client' \
    'libwayland-egl' \
    'libwebp' \
    'libxkbcommon' \
    'libxml2' \
    'pango' \
    'pipewire-libs' \
    'polkit-libs' \
    'sdbus-cpp'

# Build Noctalia from source inside a toolbox (see toolbox.sh).
toolbox rm -f 'noctalia' || true
toolbox create 'noctalia'
toolbox run --container='noctalia' bash "${THIS_DIR}/build-noctalia-in-toolbox.sh"

# Utilities
sudo dnf install --setopt=install_weak_deps=False --assumeyes \
    'wpctl'
