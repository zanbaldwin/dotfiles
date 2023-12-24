#!/bin/bash

export GIT_DISCOVERY_ACROSS_FILESYSTEM=0

# This function relies on Git repositories having sensible tag names. Do not rely on it.
function latest_stable_version {
    GIT_DIR="${1:-$(pwd)}"
    # Fetch all tags that contain at least a MAJOR.MINOR, filtering out hyphens (alpha, beta, rc, etc), and print the latest.
    git -C "${GIT_DIR}" tag --list --sort="version:refname" \
        | rg -e '\d+\.\d+' \
        | rg -v 'alpha|ALPHA|beta|BETA|rc|RC|-' \
        | sort --version-sort \
        | tail -n1
}

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
                command git --help
            fi
        else
            command git "$@"
        fi
    }
}
