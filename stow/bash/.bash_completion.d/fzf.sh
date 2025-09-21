#!/usr/bin/env bash

if command -v "fzf" >"/dev/null" 2>&1; then
    eval "$(fzf --bash)"
fi
