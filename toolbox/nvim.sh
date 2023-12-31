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

ASTRONVIM="${HOME}/.config/nvim"

rm -rf "${ASTRONVIM}"
rm -rf "${HOME}/.local/share/nvim"
rm -rf "${HOME}/.local/share/applications/nvim.desktop"
rm -rf "${HOME}/.local/state/nvim"
rm -rf "${HOME}/.cache/nvim"

git clone "https://github.com/AstroNvim/AstroNvim.git" "${ASTRONVIM}"
git -C "${ASTRONVIM}" checkout "$(nvim_stable_version "${ASTRONVIM}")"

if ! command -v "nvim" >"/dev/null" 2>&1; then
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
        cp --force --recursive /tmp/nvim-linux64/* "${HOME}/.local/"
    else
        echo >&2 "Could not determine asset URL of latest NVim release."
        exit 1
    fi
fi
