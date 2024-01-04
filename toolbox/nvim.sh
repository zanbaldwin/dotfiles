#!/usr/bin/env bash

nvim_stable_version() {
    GIT_DIR="${1:-$(pwd)}"
    # Fetch all tags that contain at least a MAJOR.MINOR, filtering out hyphens (alpha, beta, rc, etc), and print the latest.
    # Escape to use the original `grep` so we know what we're getting (just in case `rg` is aliased), and use PCRE2 flag.
    git -C "${GIT_DIR}" tag --list --sort="version:refname" \
        | \grep -P -e '\d+\.\d+' \
        | \grep -P -v 'alpha|ALPHA|beta|BETA|rc|RC|-' \
        | sort --version-sort \
        | tail -n1
}

function delete_nvim_installation {
    rm -rf \
        "${HOME}/.local/bin/nvim" \
        "${HOME}/.local/lib/nvim" \
        "${HOME}/.local/man/man1/nvim.1" \
        "${HOME}/.local/share/applications/nvim.desktop" \
        "${HOME}/.local/share/icons/hicolor/128x128/apps/nvim.png" \
        "${HOME}/.local/share/locale/"*"/LC_MESSAGES/nvim.mo" \
        "${HOME}/.local/share/nvim"
}

function delete_nvim_distribution {
    rm -rf \
        "${HOME}/.config/nvim" \
        "${HOME}/.local/state/nvim" \
        "${HOME}/.cache/nvim"
}

function install_nvim_to_user_directory {
    if [ "$(uname -m)" != "x86_64" ]; then
        echo >&2 "Installer only able to install for AMD64; please install NVim for correct architecture manually."
        exit 1
    fi

    if ! command -v "jq" >"/dev/null" 2>&1; then
        echo >&2 "Could not determine latest release tarball of NVim. Install \"jq\" CLI tool first."
        exit 1
    fi

    ASSET_NAME="nvim-linux64.tar.gz"
    META="$(curl -sfL "https://api.github.com/repos/neovim/neovim/releases/latest")"
    DOWNLOAD_URL="$(echo "${META}" | jq -r ".assets[] | select(.name == \"${ASSET_NAME}\") | .browser_download_url")"
    if [ ! -z "${DOWNLOAD_URL}" ]; then
        curl -sfL "${DOWNLOAD_URL}" --output "/tmp/nvim.tar.gz"
        tar --extract --gzip --file "/tmp/nvim.tar.gz" --directory "/tmp"
        cp --force --recursive "/tmp/nvim-linux64/"* "${HOME}/.local/"
    else
        echo >&2 "Could not determine asset URL of latest NVim release."
        exit 1
    fi

    rm -f "/tmp/nvim.tar.gz"
    rm -rf "/tmp/nvim-linux64"
}

function print_usage {
    SCRIPT_NAME="$(basename "$(readlink -f "$0")")"
    echo >&2 "Usage: ${SCRIPT_NAME} [-r|--reinstall]"
    echo >&2 "  Install Neovim and the AstroNVim distribution, if not already installed."
    exit 0
}

REINSTALL=false

# Shortform Arguments
while getopts ":hr" ARG; do
    case "${ARG}" in
        "h")
            print_usage
        ;;
        "r")
            REINSTALL=true
        ;;
    esac
done
# Longform Arguments
for ARG in "$@"; do
    case "${ARG}" in
        "--help")
            print_usage
        ;;
        "--reinstall")
            REINSTALL=true
        ;;
    esac
done

if ${REINSTALL}; then
    echo >&2 "Deleting existing Neovim installation and distribution..."
    delete_nvim_installation
    delete_nvim_distribution
fi

NVIM_CONFIG="${HOME}/.config/nvim"

if ! command -v "nvim" >"/dev/null" 2>&1; then
    echo >&2 "Installing Neovim..."
    install_nvim_to_user_directory
else
    echo >&2 "Neovim already installed."
fi

if [ ! -d "${HOME}/.config/nvim" ]; then
    echo >&2 "Installing Neovim distribution (AstroNVim)..."
    git clone "https://github.com/AstroNvim/AstroNvim.git" "${HOME}/.config/nvim"
    git -C "${HOME}/.config/nvim" checkout "$(nvim_stable_version "${HOME}/.config/nvim")"
else
    echo >&2 "Neovim distribution (AstroNVim) already installed."
fi
