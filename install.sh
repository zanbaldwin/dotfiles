# This script was designed to be run on fresh Ubuntu installations.

if [ "$(id -u)" != "0" ]; then
    echo >&2 "Package installation script must be run as root.";
    exit 1;
fi

apt update
apt dist-upgrade -y
apt install -y \
    bash \
    bash-completion \
    build-essential \
    curl \
    git \
    gnupg-agent \
    gnupg-utils \
    gnupg2 \
    htop \
    make \
    mosh \
    nano \
    ncdu \
    neofetch \
    rsync \
    scdaemon \
    sl \
    stow \
    tmux \

# These Snap packages don't conform to the secure way. Use classic installation.
snap install --stable --classic aws-cli
snap install --stable --classic nvim
snap install --stable --classic phpstorm
snap install --stable --classic slack

snap install --stable bitwarden
snap install --stable chromium
snap install --stable chromium-ffmpeg
snap install --stable httpie
snap install --stable multipass
snap install --stable vlc

snap refresh

# Install Rust (+ Cargo)
# Yeah, this is not good. Running an arbitrary script from the internet. Don't do this. Except for this time.
command -v "cargo" >/dev/null 2>&1 && { \
    curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" > "/tmp/rustup.sh"; \
    sh /tmp/rustup.sh -qy; \
    source "${HOME}/.cargo/env"; \
} || { \
    rustup update; \
}

### Manual Install
cargo install bat
cargo install exa
# [Discord](https://discord.com/api/download?platform=linux&format=deb)
# [Docker](https://docs.docker.com/engine/install/ubuntu/)
# [Docker Compose](https://docs.docker.com/compose/install/)
# [NordVPN](https://support.nordvpn.com/Connectivity/Linux/1325531132/Installing-and-using-NordVPN-on-Debian-Ubuntu-Raspberry-Pi-Elementary-OS-and-Linux-Mint.htm)

# Stow Configuration Files
SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"
stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" bash
stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" editor
stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" git
stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" gnupg
stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" nvim
stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" ssh
stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" tmux

# Other
if [ ! -f "/etc/bash_completion.d/exa" ]; then
    curl "https://raw.githubusercontent.com/ogham/exa/master/completions/bash/exa" | sudo tee "/etc/bash_completion.d/exa
fi

# Force Chromium to always allow Unsecured HTTP for Localhost, without force redirecting to HTTPS.
if [ ! -f "/etc/opt/chrome/policies/managed/policies.json" ]; then
    mkdir -p "/etc/opt/chrome/policies/managed"
    touch "/etc/opt/chrome/policies/managed/policies.json"
fi
echo '{"HSTSPolicyBypassList":["localhost"]}' > "/etc/opt/chrome/policies/managed/policies.json"
