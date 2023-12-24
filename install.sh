#!/usr/bin/env bash

THIS_DIR="$(dirname "$(readlink -f "$0")")"

# Get the command requiring `sudo` out of the way first, so that the user can
# leave this running.
{ \
    echo "[[registry]]"; \
    echo "location = 'localhost:5000'"; \
    echo "insecure = true"; \
} | sudo tee --append "/etc/containers/registries.conf"

# Installation scripts that work on the host, rather than a toolbox container.
bash "${THIS_DIR}/toolbox/apps.sh"
bash "${THIS_DIR}/toolbox/fonts.sh"
bash "${THIS_DIR}/toolbox/gnome.sh"

toolbox create rust
toolbox run --container="rust" bash "${THIS_DIR}/toolbox/rust.sh"
toolbox run --container="rust" bash "${THIS_DIR}/toolbox/zellij.sh"

toolbox create php
toolbox run --container="php" bash "${THIS_DIR}/toolbox/php.sh"

toolbox create stow
toolbox run --container="stow" bash "${THIS_DIR}/toolbox/stow.sh"

podman build --target="gnome" --tag="localhost:5000/zanbaldwin/silverblue:39" "${THIS_DIR}/oci"
podman run -d --name="registry" --publish="5000:5000" "docker.io/library/registry:2"
podman push "localhost:5000/zanbaldwin/silverblue:39"
rpm-ostree rebase "ostree-unverified-registry:localhost:5000/zanbaldwin/silverblue:39"
systemctl reboot

# Things to do afterwards:
# - Copy and/or generate SSH Keys and Config
# - `DOCKER_HOST=unix:///run/podman/podman.sock sudo docker compose --project-directory "${HOME}/code" up -d`
# - MkCert and Proxy entries for local website development. Mailhog and Proxy, at the least.
