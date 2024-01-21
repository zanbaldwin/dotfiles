#!/usr/bin/env bash

[ -s "${NVM_DIR}/bash_completion" ] && source "${NVM_DIR}/bash_completion"

if command -v "cargo-shuttle" >"/dev/null" 2>&1; then
    eval "$(cargo-shuttle generate shell bash)"
fi
