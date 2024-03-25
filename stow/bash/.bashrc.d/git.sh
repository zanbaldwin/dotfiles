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
                command "jj" --ignore-working-copy obslog --stat

                echo ""
                echo -e "\e[4mHistory Log:\e[0m"
                command "jj" --ignore-working-copy log --limit=7 --template="builtin_log_comfortable"
            fi
        elif [ "${1}" == "up" ]; then
            shift
            jj_up_branch "$@"
        else
            command "jj" "$@"
        fi
    }
}

function jj_up_branch {
    BRANCH_NAME="${1}"
    if [ -z "${BRANCH_NAME}" ]; then
        echo >&2 "Specify a branch name."
        return 1
    fi

    if [ "$(jj branch list "${BRANCH_NAME}")" == "" ]; then
        jj branch create "${BRANCH_NAME}" --revision "@-"
        echo "Created new branch \"${BRANCH_NAME}\"."
    else
        jj branch set "${BRANCH_NAME}" --revision "@-"
        echo "Updated branch \"${BRANCH_NAME}\"."
    fi
}
