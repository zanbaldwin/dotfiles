# This script was designed to be run on fresh Ubuntu installations.

if [ "$(id -u 2>/dev/null)" = "0" ]; then
    echo >&2 "Do not run this installation script as root/sudo."
    echo >&2 "A reference to the original user running it is needed."
    exit 1
fi

install_as_sudo() {
    ORIGINAL_USER="$1"

    apt update
    apt dist-upgrade -y
    apt install -y \
        bash \
        bash-completion \
        build-essential \
        ca-certificates \
        curl \
        dconf-cli \
        fonts-firacode \
        git \
        gnupg-agent \
        gnupg-utils \
        gnupg2 \
        htop \
        lsb-release \
        make \
        mosh \
        nano \
        ncdu \
        neofetch \
        rsync \
        scdaemon \
        sl \
        stow \
        tmux

    # Docker Engine
    curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | gpg --dearmor >"/usr/share/keyrings/docker-archive-keyring.gpg"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >"/etc/apt/sources.list.d/docker.list"
    apt update
    apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io

    usermod -aG "docker" "${ORIGINAL_USER}"
    newgrp "docker"

    snap install --stable --classic aws-cli
    snap install --stable --classic phpstorm
    snap install --stable --classic code
    snap install --stable --classic slack
    snap install --stable bitwarden
    snap install --stable chromium
    snap install --stable chromium-ffmpeg
    snap install --stable httpie
    snap install --stable spotify
    snap install --stable vlc
    snap refresh

    # Other
    if [ ! -f "/etc/bash_completion.d/exa" ]; then
        curl -fsSL "https://raw.githubusercontent.com/ogham/exa/master/completions/bash/exa" >"/etc/bash_completion.d/exa"
    fi

    # Force Chromium to always allow Unsecured HTTP for Localhost, without force redirecting to HTTPS.
    if [ ! -f "/etc/opt/chrome/policies/managed/policies.json" ]; then
        mkdir -p "/etc/opt/chrome/policies/managed"
        touch "/etc/opt/chrome/policies/managed/policies.json"
    fi
    echo '{"HSTSPolicyBypassList":["localhost"]}' >"/etc/opt/chrome/policies/managed/policies.json"
}

install_as_user() {
    # Install Rust (+ Cargo)
    # Yeah, this is not good. Running an arbitrary script from the internet. Don't do this. Except for this time.
    command -v "cargo" >/dev/null 2>&1 && { \
        rustup update; \
    } || { \
        curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" > "/tmp/rustup.sh" && { \
            sh /tmp/rustup.sh -qy; \
            source "${HOME}/.cargo/env"; \
        } || { echo >&2 "Error downloading Rustlang installation script."; } \
    }

    ### Manual Install
    command -v "cargo" >/dev/null 2>&1 && { \
        cargo install bat; \
        cargo install exa; \
    }

    # Stow Configuration Files
    SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" bash
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" editor
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" git
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" gnupg
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" ssh
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" tmux

    dconf write "/org/gnome/desktop/input-sources/xkb-options" "['caps:swapescape']"
}

echo >&2 "This installation script needs root access to install system packages."
# These things need to be installed as the root user (pass in a reference to the current user).
sudo sh -c "$(declare -f install_as_sudo); install_as_sudo \"${USER}\"";
# The rest need to be installed as the current user so they affect that user's home directory and environment.
install_as_user

# [Discord](https://discord.com/api/download?platform=linux&format=deb)
# [Docker Compose](https://docs.docker.com/compose/install/)
# [NordVPN](https://support.nordvpn.com/Connectivity/Linux/1325531132/Installing-and-using-NordVPN-on-Debian-Ubuntu-Raspberry-Pi-Elementary-OS-and-Linux-Mint.htm)
# [VirtualBox](https://www.virtualbox.org/wiki/Linux_Downloads); use deb file instead of repository.




