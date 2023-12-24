#!/bin/bash

command -v "dconf" 1>"/dev/null" 2>&1 || {
    echo 1>&2 "dconf not available"
    exit 1
}

if [ -f "${HOME}/.config/dconf/custom.ini" ]; then
    dconf load / < "${HOME}/.config/dconf/custom.ini"
fi
