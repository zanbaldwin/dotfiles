#!/usr/bin/env bash
THIS_DIR="$(dirname "$(readlink -f -- "$0")")"

# Niri
sudo dnf install  --setopt=install_weak_deps=False --assumeyes 'niri'

# Kanshi
sudo dnf install  --setopt=install_weak_deps=False --assumeyes 'kanshi'

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

# Quickshell
sudo dnf install  --setopt=install_weak_deps=False --assumeyes 'jemalloc'
toolbox rm -f quickshell || true
toolbox create quickshell
toolbox run --container='quickshell' bash "${THIS_DIR}/toolbox.sh"
