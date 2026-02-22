#!/bin/bash

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f -- "$0")")"

if command -v 'apt-get' >'/dev/null' 2>&1; then
    sudo apt-get install -y 'xz-utils';
elif command -v 'dnf' >'/dev/null' 2>&1; then
    sudo dnf install --assumeyes 'xz';
fi

mkdir -p "${HOME}/.local/share/fonts"
find "${TOOLBOX_SCRIPT_DIRECTORY}/../fonts" -mindepth 1 -maxdepth 1 -type f -name "*.tar.xz" \
    -exec tar --extract --verbose --xz \
        --file "{}" \
        --directory "${HOME}/.local/share/fonts" \;

fc-cache --force --verbose
