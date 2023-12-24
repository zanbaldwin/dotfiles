#!/bin/bash

# Explicitly create directories that shouldn't be made into symbolic links.
mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.cargo" \
    "${HOME}/.config" \
    "${HOME}/.ssh"

sudo dnf install --assumeyes \
    "stow"

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
    "tmux"
