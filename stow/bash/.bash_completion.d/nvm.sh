#!/usr/bin/env bash

[ -z "${NVM__DIR}" ] && [ -s "${NVM_DIR}/bash_completion" ] && source "${NVM_DIR}/bash_completion"

if command -v  'fnm' >'/dev/null' 2>&1; then
    eval "$(fnm env --use-on-cd --version-file-strategy 'recursive' --shell 'bash')"
fi
