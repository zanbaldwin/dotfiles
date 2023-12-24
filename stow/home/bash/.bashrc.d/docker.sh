#!/bin/bash

# Old habits die hard...
alias docker-compose="docker compose"
alias docker-composer="docker compose"

if command -v "docker" >"/dev/null" 2>&1 && ! (docker version 2>"/dev/null" | grep "Podman" >"/dev/null" 2>&1); then
    # Actually have the real Docker installed.
    function docker {
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
    # The Podman (v4.8.0) API is not yet compatible with Docker Compose
    # defaulting to BuildKit yet when Compose configuration files have more than
    # one service that contains a build configuration.
    export DOCKER_BUILDKIT=0

    # Docker is symlinked to Podman (probably the "podman-docker" package).
    function docker {
        if [[ ("$1" = "compose") || ("$1" = "composer") ]]; then
            shift
            # If using Podman instead of Docker then Docker Compose would have
            # been installed as a stand-alone binary instead of a Docker CLI Plugin.
            command docker-compose "$@"
        else
            command podman "$@"
        fi
    }
elif [[ -f "/run/.containerenv" || -f "/run/.toolboxenv" ]]; then
    command -v "flatpak-spawn" >"/dev/null" 2>&1 && {
        alias docker="flatpak-spawn --host -- docker"
    }
fi

# Podman Compose
# Sometimes I like to use my own Docker Compose setup for projects.
# This will correctly find the `docker-compose[.override].yaml` and run it in
# the current directory as project root.
function pcom {
    if [ "$#" -lt 1 ]; then
        echo >&2 "You must specify a relative directory to where the docker-compose.yaml configuration exists.";
        return;
    fi
    COMPOSE_DIR="${1}"
    if [ ! -d "$(pwd)/${COMPOSE_DIR}" ]; then
        echo >&2 "Directory \"${COMPOSE_DIR}\" could not be found in current working directory.";
        return;
    fi
    shift;
    if [ ! -f "$(pwd)/${COMPOSE_DIR}/docker-compose.yaml" ]; then
        echo >&2 "Could not find docker-compose.yaml in \"${COMPOSE_DIR}\"";
    fi
    # shellcheck disable=SC2090
    ARGS=("--file" "$(pwd)/${COMPOSE_DIR}/docker-compose.yaml");
    if [ -f "$(pwd)/${COMPOSE_DIR}/docker-compose.override.yaml" ]; then
        ARGS+=("--file" "$(pwd)/${COMPOSE_DIR}/docker-compose.override.yaml");
    fi
    ARGS+=("--project-directory" "$(pwd)");
    # shellcheck disable=SC2206
    ARGS+=($@);
    # shellcheck disable=SC2068
    command docker-compose ${ARGS[@]}
}
