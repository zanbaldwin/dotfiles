#!/bin/bash

# Explicitly create directories that shouldn't be made into symbolic links.
mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.cargo" \
    "${HOME}/code" \
    "${HOME}/.config/autostart" \
    "${HOME}/.config/flakes" \
    "${HOME}/.local/share/applications" \
    "${HOME}/.ssh/conf.d" \
    "${HOME}/.ssh/keys"

if ! command -v "stow" >"/dev/null" 2>&1; then
    if command -v "dnf" >"/dev/null" 2>&1; then
        sudo dnf install --assumeyes "stow"
    elif command -v "apt-get" >"/dev/null" 2>&1; then
        # Binary "apt" exists on macOS for some reason.
        sudo apt-get install -y "stow"
    elif command -v "brew" >"/dev/null" 2>&1; then
        sudo brew install "stow"
    fi
else
    echo "GNU Stow already installed."
fi

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"

HOME_STOW_PACKAGES="$(find "${TOOLBOX_SCRIPT_DIRECTORY}/../stow" -maxdepth 1 -mindepth 1 -type d | sed "s#${TOOLBOX_SCRIPT_DIRECTORY}/../stow/##g")"
# shellcheck disable=SC2086
stow --dir="${TOOLBOX_SCRIPT_DIRECTORY}/../stow" --target="${HOME}" --stow ${HOME_STOW_PACKAGES}
echo "Stowed into ${HOME}: ${HOME_STOW_PACKAGES}"
