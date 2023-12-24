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

    systemctl enable --now "libvirtd"
    systemctl enable --now "podman"
    systemctl enable --now "podman.socket"
    systemctl enable --now "tlp.service" || true

    grep -E '^libvirt:' "/usr/lib/group" >> "/etc/group"
    usermod -aG "libvirt" "${USER}"

    # Attempting to both read and write the same file in the same pipeline; use `tee`. shellcheck disable=SC2002
    cat "/etc/sudoers" | grep -v "secure_path" | tee "/etc/sudoers" >"/dev/null" 2>&1
}

sudo sh -c "$(declare -f enable_services); enable_services \"$(whoami)\"";
# Rootless Podman
systemctl --user enable --now "podman.socket"
