#!/usr/bin/env bash

# If we're inside a container, check whether it's rootless or not.
if [ -f "/run/.containerenv" ]; then
    source "/run/.containerenv" >"/dev/null" 2>&1
    if [[ "${engine:-}" =~ podman* ]]; then
        if [ "${rootless:-}" = "1" ]; then
            echo "Podman<User>"
        else
            echo "Podman<System>"
        fi
        exit 0
    fi
fi

# If we're operating on a remote machine, display that.
if [ -n "${DOCKER_MACHINE_NAME}" ]; then
    echo "${DOCKER_MACHINE_NAME}"
    exit 0
fi
# If we're using a specific Docker context (unlikely if Podman
# is being used), display that.
if [ -n "${DOCKER_CONTEXT}" ]; then
    echo "${DOCKER_CONTEXT}"
    exit 0
fi

# Standard unix socket for rootless Podman?
if [ "${DOCKER_HOST:-}" = "unix:///run/user/$(id -u)/podman/podman.sock" ]; then
    echo "Podman<User>"
    exit 0
fi

# Standard unix socket for root Podman?
if [ "${DOCKER_HOST:-}" = "unix:///run/podman/podman.sock" ]; then
    echo "Podman<System>"
    exit 0
fi

# If a non-standard unix socket is being used then don't
# display it (likely very long and take up too much space).
if [[ "${DOCKER_HOST:-}" =~ unix* ]]; then
    exit 1
fi

echo "${DOCKER_HOST}"

exit 1
