#!/bin/bash

# Old habits die hard...
alias docker-composer="docker-compose"
if which "docker" >"/dev/null" 2>&1; then
    docker() {
        if [[ ("$1" = "compose") || ("$1" = "composer") ]]; then
            shift
            # shellcheck disable=SC2068
            command docker-compose $@
        elif [[ "$1" = "machine" ]]; then
            shift
            # shellcheck disable=SC2068
            command docker-machine $@
        else
            # shellcheck disable=SC2068
            command docker $@
        fi
    }
elif command -v "podman" >"/dev/null" 2>&1; then
    docker() {
        if [[ ("$1" = "compose") || ("$1" = "composer") ]]; then
            shift
            # shellcheck disable=SC2068
            command docker-compose $@
        else
            # shellcheck disable=SC2068
            command podman $@
        fi
    }
fi
