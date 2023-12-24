#!/bin/bash

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"

find "${TOOLBOX_SCRIPT_DIRECTORY}/../fonts" -mindepth 1 -maxdepth 1 -type f -name "*.tar.xz" \
    -exec tar --extract --verbose --xz \
        --file "{}" \
        --directory "${HOME}/.local/share/fonts" \;

fc-cache --force --verbose
