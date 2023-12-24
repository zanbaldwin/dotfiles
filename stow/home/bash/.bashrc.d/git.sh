#!/bin/bash

# This function relies on Git repositories having sensible tag names. Do not rely on it.
latest_stable_version () {
    #local GIT_DIR="${1:-$(pwd)}"
    # Fetch all tags that contain at least a MAJOR.MINOR, filtering out hyphens (alpha, beta, rc, etc), and print the latest.
    git -C "${GIT_DIR}" tag --list --sort="version:refname" \
        | rg -e '\d+\.\d+' \
        | rg -v 'alpha|ALPHA|beta|BETA|rc|RC|-' \
        | tail -n1
}