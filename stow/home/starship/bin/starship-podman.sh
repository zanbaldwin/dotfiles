#!/usr/bin/env bash

if [ -n "${DOCKER_MACHINE_NAME}" ]; then
    echo "${DOCKER_MACHINE_NAME}"
    exit 0
fi
if [ -n "${DOCKER_CONTEXT}" ]; then
    echo "${DOCKER_CONTEXT}"
    exit 0
fi

if [ "${DOCKER_HOST:-}" = "unix:///run/user/$(id -u)/podman/podman.sock" ]; then
    echo "Podman<User>"
    exit 0
fi

if [ "${DOCKER_HOST:-}" = "unix:///run/podman/podman.sock" ]; then
    echo "Podman<System>"
    exit 0
fi

if [[ "${DOCKER_HOST:-}" =~ unix* ]]; then
    exit 1
fi

echo "${DOCKER_HOST}"

exit 1
