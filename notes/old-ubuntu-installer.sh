#!/bin/bash
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
    ## Standard Repository Software
    apt install -y --no-install-recommends --no-install-suggests \
        bash \
        bash-completion \
        build-essential \
        ca-certificates \
        curl \
        dconf-cli \
        direnv \
        distrobox \
        fonts-firacode \
        fzy \
        git \
        gnupg-agent \
        gnupg-utils \
        gnupg2 \
        htop \
        jq \
        lsb-release \
        make \
        mosh \
        nano \
        ncdu \
        neofetch \
        rsync \
        scdaemon \
        shellcheck \
        sl \
        stow \
        tmux \
        xclip
    ## Snap Repository Software
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

    ## Custom Software

    # Docker Engine
    curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" \
        | gpg --dearmor >"/usr/share/keyrings/docker-archive-keyring.gpg"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" >"/etc/apt/sources.list.d/docker.list"
    # Hashicorp
    curl -fsSL "https://apt.releases.hashicorp.com/gpg" \
        | gpg --dearmor >"/usr/share/keyrings/hashicorp-archive-keyring.gpg"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" >"/etc/apt/sources.list.d/hashicorp.list"
    # Symfony CLI (not happy about the lack of signed packages there, Fabien)
    echo "deb [arch=$(dpkg --print-architecture) trusted=yes] https://repo.symfony.com/apt/ /" >"/etc/apt/sources.list.d/symfony-cli.list"
    apt update
    apt install -y --no-install-recommends --no-install-suggests \
        docker-ce \
        docker-ce-cli \
        docker-compose-plugin \
        containerd.io \
        symfony-cli \
        terraform
    usermod -aG "docker" "${ORIGINAL_USER}"

    ## Docker Compose
    COMPOSE_VERSION="$(curl -fsSL "https://api.github.com/repos/docker/compose/releases/latest" | jq -r ".tag_name")"
    curl -fsSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o "/usr/local/bin/docker-compose"
    curl -fsSL "https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose" >"/etc/bash_completion.d/docker-compose"
    chmod +x "/usr/local/bin/docker-compose"

    ## Exa (ll-alias) Auto-completion
    EXA_VERSION="$(curl -fsSL "https://api.github.com/repos/ogham/exa/releases/latest" | jq -r ".tag_name")"
    # Unreleased Bash completion is better, remove following line whenever a version is released after v0.10.1
    EXA_VERSION="master"
    curl -fsSL "https://raw.githubusercontent.com/ogham/exa/${EXA_VERSION}/completions/bash/exa" >"/etc/bash_completion.d/exa"

    # Force Chromium to always allow Unsecured HTTP for Localhost, without force
    # redirecting to HTTPS. Add the string "localhost" to the HSTSPolicyBypassList
    # array inside already existing JSON, defaulting to an empty object when the
    # file does not exist or is invalid JSON.
    TEMPFILE="$(mktemp)" # (to prevent race conditions inside pipelines)
    mkdir -p "/etc/opt/chrome/policies/managed"
    (cat "/etc/opt/chrome/policies/managed/policies.json" 2>/dev/null || echo '{}') \
        | (grep "." || echo '{}') \
        | (jq 2>/dev/null || echo '{}') \
        | jq '.HSTSPolicyBypassList|=(.+["localhost"]|unique)' >"${TEMPFILE}" \
        && mv "${TEMPFILE}" "/etc/opt/chrome/policies/managed/policies.json"

    PHP_VERSION="8.1"
    apt install -y --no-install-recommends --no-install-suggests \
        "php${PHP_VERSION}-cli" \
        "php${PHP_VERSION}-curl" \
        "php${PHP_VERSION}-dev" \
        "php${PHP_VERSION}-intl" \
        "php${PHP_VERSION}-mbstring" \
        "php${PHP_VERSION}-mysql" \
        "php${PHP_VERSION}-opcache" \
        "php${PHP_VERSION}-readline" \
        "php${PHP_VERSION}-sqlite3" \
        "php${PHP_VERSION}-xdebug" \
        "php${PHP_VERSION}-xml" \
        "php${PHP_VERSION}-zip"
    echo "xdebug.log_level=0" >>"$(php-config --ini-dir)/20-xdebug.ini"
    # Vulcan Logic Disassembler is in constant beta because the ever-changing internal API.
    pecl install "vld-beta" && { echo "extension=vld.so" >"$(php-config --ini-dir)/vld.ini"; }
}

install_as_user() {
    # Install Rust (+ Cargo)
    # Yeah, this is not good. Running an arbitrary script from the internet.
    # Don't do this. Except for this time.
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
        cargo install git-delta; \
        cargo install starship; \
        cargo install onefetch; \
    }

    # Pre-create some directories so that GNU stash symlinks the files that go in them rather
    # than symlinking the directories themselves.
    mkdir -p "${HOME}/bin"
    mkdir -p "${HOME}/.config"
    mkdir -p "${HOME}/.gnupg"
    mkdir -p "${HOME}/.ssh"

    # Stow Configuration Files
    SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" alacritty
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" bash
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" cargo
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" editor
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" git
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" gnupg
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" ssh
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" starship
    stow --dir="${SCRIPT_DIRECTORY}" --target="${HOME}" tmux

    dconf write "/org/gnome/desktop/input-sources/xkb-options" "['caps:swapescape']"
}

install_alacritty() {
    VERSION="${1:-v0.10.1}"
    # Because the following requires Rust to compile.
    apt install -y --no-install-recommends --no-install-suggests \
        cmake \
        pkg-config \
        libfreetype6-dev \
        libfontconfig1-dev \
        libxcb-xfixes0-dev \
        libxkbcommon-dev \
        python3
    git clone "https://github.com/alacritty/alacritty.git" "/tmp/alacritty" --branch "${VERSION}"
    (cd "/tmp/alacritty"; cargo build --release)
    cp "/tmp/alacritty/target/release/alacritty" "/usr/local/bin/alacritty"
    tic -xe alacritty,alacritty-direct "/tmp/alacritty/extra/alacritty.info"
    cp "/tmp/alacritty/extra/logo/alacritty-term.svg" "/usr/share/pixmaps/Alacritty.svg"
    cp "/tmp/alacritty/extra/linux/Alacritty.desktop" "/usr/share/applications/alacritty.desktop"
    mkdir -p "/usr/local/share/man/man1"
    gzip -c "/tmp/alacritty/extra/alacritty.man" >"/usr/local/share/man/man1/alacritty.1.gz"
    gzip -c "/tmp/alacritty/extra/alacritty-msg.man" >"/usr/local/share/man/man1/alacritty-msg.1.gz"
    cp "/tmp/alacritty/extra/completions/alacritty.bash" "/etc/bash_completions.d/alacritty"
}

echo >&2 "This installation script needs root access to install system packages."
# These things need to be installed as the root user (pass in a reference to
# the current user).
sudo sh -c "$(declare -f install_as_sudo); install_as_sudo \"${USER}\"";
# The rest need to be installed as the current user so they affect that user's
# home directory and environment.
install_as_user

LATEST_ALACRITTY_TAG_VERSION="v0.10.1"
# sudo sh -c "$(declare -f install_alacritty); install_alacritty \"${LATEST_ALACRITTY_TAG_VERSION}\"";


# ================================================== #
# Other Software (best left for manual installation) #
# ================================================== #

# - Discord
#   https://discord.com/api/download?platform=linux&format=deb

# - NordVPN
#   https://support.nordvpn.com/Connectivity/Linux/1325531132/Installing-and-using-NordVPN-on-Debian-Ubuntu-Raspberry-Pi-Elementary-OS-and-Linux-Mint.htm
#   Note: on Ubuntu 22.04, `systemd-resolve` (which NordVPN relies on) has been renamed to `resolvectl`; run the following command:
#   - sudo ln -s /usr/bin/resolvectl /usr/bin/systemd-resolve

# - VirtualBox (use deb file instead of repository)
#   https://www.virtualbox.org/wiki/Linux_Downloads

# - Disk Usage/Free Utility
#   https://github.com/muesli/duf
