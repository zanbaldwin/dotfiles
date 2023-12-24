#!/bin/bash

# Old habits die hard...
alias docker-composer="docker-compose"
if command -v "docker" >"/dev/null" 2>&1; then
    docker() {
        if [[ ("$1" = "compose") || ("$1" = "composer") ]]; then
            shift
            command docker-compose $@
        elif [[ "$1" = "machine" ]]; then
            shift
            command docker-machine $@
        else
            command docker $@
        fi
    }
elif command -v "podman" >"/dev/null" 2>&1; then
    alias docker="podman"
fi
