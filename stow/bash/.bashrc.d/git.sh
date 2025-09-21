#!/bin/bash

export GIT_DISCOVERY_ACROSS_FILESYSTEM=0

BASHRC_INCLUDE_DIRECTORY="$(dirname "$(readlink -f "$0")")"
if [ -f "${BASHRC_INCLUDE_DIRECTORY}/../../../toolbox/stable-version.sh" ]; then
    . "${BASHRC_INCLUDE_DIRECTORY}/../../../toolbox/stable-version.sh"
fi

# Alias-inception
alias st='git st'

# `git <arg>` runs `git <arg>`
# `git` (in a Git repository) runs `gitui`
# `git` (not in a Git repository) runs `git --help`
command -v "gitui" >"/dev/null" 2>&1 && {
    function git {
        if [ $# -eq 0 ]; then
            GIT_DIR="$(git rev-parse --git-dir)"
            if [ -d "${GIT_DIR}" ]; then
                gitui --watcher --directory="${GIT_DIR}"
            else
                command "git" --help
            fi
        else
            command "git" "$@"
        fi
    }
}

command -v "jj" >"/dev/null" 2>&1 && {
    function jj {
        if [ $# -eq 0 ]; then
            # Don't bother checking `jj root` to see if we're in a directory,
            # since the error message from `jj st` is better to display than any
            # other alternative.
            if command "jj" "status"; then
                echo ""
                echo -e "\e[4mRevision Changes:\e[0m"
                command "jj" --ignore-working-copy obslog --stat  --template="builtin_log_comfortable"

                echo ""
                echo -e "\e[4mHistory Log:\e[0m"
                command "jj" --ignore-working-copy log --limit=7 --template="builtin_log_comfortable"
            fi
        else
            command "jj" "$@"
        fi
    }
}
