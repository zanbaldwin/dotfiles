#!/bin/bash

# Explicitly create directories that shouldn't be made into symbolic links.
mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.cargo" \
    "${HOME}/.config" \
    "${HOME}/.ssh"

if ! command -v "stow" >"/dev/null" 2>&1; then
    sudo dnf install --assumeyes \
        "stow"
fi

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"
stow --dir="${TOOLBOX_SCRIPT_DIRECTORY}/../stow" --target="${HOME}" --stow \
    "bash" \
    "btop" \
    "cargo" \
    "editor" \
    "flatpak" \
    "git" \
    "ssh" \
    "starship" \
    "tmux" \
    "zellig"
