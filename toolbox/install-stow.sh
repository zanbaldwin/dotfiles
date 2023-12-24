#!/bin/bash

# Explicitly create directories that shouldn't be made into symbolic links.
mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.config" \
    "${HOME}/.ssh"

sudo dnf install --assumeyes \
    stow

stow --target="${HOME}" --stow \
    "bash" \
    "cargo" \
    "editor" \
    "flatpak" \
    "git" \
    "ssh" \
    "starship" \
    "tmux"
