#!/bin/bash

if [ -f "/run/.containerenv" ]; then
    echo >&2 "Must be run on root filesystem, outside of container.";
    exit 1;
fi

if [ "$(id -u)" == "0" ]; then
    echo >&2 "Do not run as root; run as sudo instead.";
    exit 1;
fi

function enable_services() {
    USER="${1}"

    if [ "$(id -u)" != "0" ]; then
        echo >&2 "Services must be enabled as root.";
        exit 1;
    fi

    if ! id -u "${USER}" >"/dev/null" 2>&1; then
        echo >&2 "Invalid username to add to services.";
        exit 1;
    fi

    usermod -aG "libvirt" "${USER}"
}

sudo sh -c "$(declare -f enable_services); enable_services \"$(whoami)\"";

systemctl --user enable --now "podman.socket"
systemctl --user enable --now "podman-restart.service"
systemctl --user enable --now "flatpak-update.service"
