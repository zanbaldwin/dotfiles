#!/usr/bin/env bash

if command -v "cargo-shuttle" >"/dev/null" 2>&1; then
    eval "$(cargo-shuttle generate shell bash)"
fi
