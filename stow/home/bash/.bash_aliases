#!/usr/bin/env bash

# Some distros, like Ubuntu and macOS, automatically call this file.
# Other distros, like Fedora, don't call this file and skip straight to loading scripts in the `.bashrc.d` directory.

if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*.sh; do
        if [ -f "${rc}" ]; then
            # shellcheck source="/dev/null"
            source "${rc}"
        fi
    done
fi
unset rc
