#!/bin/bash

# Old habits die hard...
alias docker-compose="docker compose"
alias docker-composer="docker compose"

if command -v "docker" >"/dev/null" 2>&1 && ! (docker version 2>"/dev/null" | grep "Podman" >"/dev/null" 2>&1); then
    # Actually have Docker installed.
    docker() {
        if [[ ("$1" = "composer") || ("$1" = "composer") ]]; then
            shift
            command docker compose "$@"
        else
            command docker "$@"
        fi
    }
elif command -v "podman" >"/dev/null" 2>&1; then
    # If Podman is installed and "/run/user/{uid}/podman/podman.sock" does not exist then run
    # the following command (should have been run on setup in "toolbox/enable-services.yaml"):
    #   systemctl --user enable --now "podman.socket"
    DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    export DOCKER_HOST

    # Docker is symlinked to Podman (probably the "podman-docker" package).
    docker() {
        if [[ ("$1" = "compose") || ("$1" = "composer") ]]; then
            shift
            # If using Podman instead of Docker then Docker Compose would have
            # been installed as a stand-alone binary instead of a Docker CLI Plugin.
            command docker-compose "$@"
        else
            command podman "$@"
        fi
    }
fi
