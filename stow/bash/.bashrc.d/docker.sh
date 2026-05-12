#!/bin/bash

# Old habits die hard...
alias docker-compose="docker compose"
alias docker-composer="docker compose"

alias aws='mkdir -p "${HOME}/.aws"; docker run --rm -it -v "${HOME}/.aws:/root/.aws:z" -v "$(pwd):$(pwd):z" -w "$(pwd)" "amazon/aws-cli:latest"'

if command -v "docker" >"/dev/null" 2>&1 && ! (docker version 2>"/dev/null" | grep "Podman" >"/dev/null" 2>&1); then
    # Actually have the real Docker installed.
    export COMPOSE_BAKE=true
# elif command -v "podman" >"/dev/null" 2>&1; then
#     # If Podman is installed and "/run/user/{uid}/podman/podman.sock" does not exist then run
#     # the following command:
#     #   systemctl --user enable --now "podman.socket"
#     DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
#     export DOCKER_HOST
#     # The Podman (v4.8.0) API is not yet compatible with Docker Compose when it
#     # uses BuildKit (for Compose configuration files that contain services with
#     # `build` configuration).
#     export DOCKER_BUILDKIT=0
#     # Docker is symlinked to Podman (possibly the "podman-docker" package).
#     # Make sure to download the `docker-compose` binary, so that `podman compose` can call it.
#     alias docker="podman"
elif [ -f "/run/.containerenv" ] || [ -f "/run/.toolboxenv" ]; then
    command -v "flatpak-spawn" >"/dev/null" 2>&1 && {
        alias docker="flatpak-spawn --host -- docker"
        alias podman="flatpak-spawn --host -- podman"
    }
fi

if command -v "podman" >"/dev/null" 2>&1; then
    function podman {
        if [ $# -eq 0 ] && command -v "podman-tui" >"/dev/null" 2>&1; then
            podman-tui
        else
            command "podman" "$@"
        fi
    }
fi

if command -v "toolbox" >'/dev/null' 2>&1; then
    alias tb="toolbox";
fi
