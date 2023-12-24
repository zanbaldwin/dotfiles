#!/bin/bash

# Old habits die hard...
alias docker-compose="docker compose"
alias docker-composer="docker compose"
if which "docker" >"/dev/null" 2>&1; then
    docker() {
        if [[ ("$1" = "composer") ]]; then
            shift
            command docker compose "$@"
        else
            command docker "$@"
        fi
    }
elif command -v "podman" >"/dev/null" 2>&1; then
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
