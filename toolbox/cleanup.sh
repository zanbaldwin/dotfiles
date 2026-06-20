#!/usr/bin/env bash
set -euo pipefail

find "${HOME}" -path "${HOME}/.local/share/containers" -prune -o -xtype l -lname '*/.dotfiles/*' -print -exec rm -- '{}' +
