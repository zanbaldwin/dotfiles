#!/usr/bin/env bash

command -v "atuin" >"/dev/null" 2>&1 && {
    eval "$(atuin init bash)"
}
