#!/usr/bin/env bash

if [ -z "${LOCAL_BASH_COMPLETION_LOADED}" ]; then
    if [ -f "${HOME}/.bash_completion" ]; then
        source "${HOME}/.bash_completion"
    fi
fi
