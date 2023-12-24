#!/bin/bash

command -v "dconf" 1>"/dev/null" 2>&1 || {
    echo 1>&2 "dconf not available"
    exit 1
}

THIS_DIR="$(dirname "$(readlink -f "$0")")"

if [ -f "${HOME}/.config/dconf/custom.ini" ]; then
    # Stow has already been run.
    dconf load / < "${HOME}/.config/dconf/custom.ini"
elif [ -f "${THIS_DIR}/stow/home/dconf/.config/dconf/custom.ini" ]; then
    # Stow has not been run.
    dconf load / < "${THIS_DIR}/stow/home/dconf/.config/dconf/custom.ini"
fi
