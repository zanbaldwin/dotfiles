#!/bin/bash

alias cp="cp -riv"
alias mv="mv -iv"
alias ln="ln -v"
alias chmod="chmod -Rv"
alias chown="chown -Rv"
alias rm="rm -v"

export PAGER="less -RFX -c"
alias less="less -S -R -N"
command -v "bat" >"/dev/null" 2>&1 && {
    alias cat="bat --theme=DarkNeon";
    alias less="bat --theme=DarkNeon";
}

# ripgrep is fast, yo.
command -v "rg" >"/dev/null" 2>&1 && {
    alias grep="rg";
}

command -v "sd" >"/dev/null" 2>&1 && {
    alias replace="sd";
}

if command -v "rg" >"/dev/null" 2>&1; then
    # Files in Directory
    # Usage: fid "pattern" ["directory"]
    function preg {
        local USAGE="$( \
            echo "Usage: preg <pattern> [<directory>] [-a|--all]"; \
            echo "  Use regular expressions to match filenames, optionally"; \
            echo "  including all hidden and ignored files."; \
        )"
        local PATTERN=""
        local DIRECTORY=""
        local ALL_FLAG=""

        if [ $# -eq 0 ]; then
            echo >&2 "${USAGE}"
            return 1
        fi

        while [ $# -ne 0 ]; do
            if [ "${1}" == "--all" ] || [ "${1}" == "-a" ]; then
                ALL_FLAG="--hidden --no-ignore"
            elif [ -z "${PATTERN}" ]; then
                PATTERN="${1}"
            else
                if [ -z "${DIRECTORY}" ]; then
                    DIRECTORY="${1}"
                else
                    echo >&2 "Too many arguments."
                    echo >&2 "${USAGE}"
                    return 1
                fi
            fi
            shift
        done

        if [ ! -z "${DIRECTORY}" ]; then
            rg --files ${ALL_FLAG} "${DIRECTORY}" 2>"/dev/null" | rg "${PATTERN}"
        else
            rg --files ${ALL_FLAG} 2>"/dev/null" | rg "${PATTERN}"
        fi
    }
fi
