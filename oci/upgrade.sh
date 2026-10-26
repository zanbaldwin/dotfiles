#!/usr/bin/env bash
set -eox pipefail

TARGET="stock"
LINUX_VERSION="${1:-7.3.0}"


THIS_DIR="$(dirname "$(readlink -f -- "$0")")"
sudo mkdir -p '/etc/containers/registries.conf.d'
{ \
    echo '[[registry]]'; \
    echo "location = 'localhost:5000'"; \
    echo 'insecure = true'; \
} | sudo tee '/etc/containers/registries.conf.d/localhost.conf'

[ -f '/etc/os-release' ] && source '/etc/os-release'
FEDORA_VERSION="${VERSION_ID:-44}"
FEDORA_VERSION="${2:-${FEDORA_VERSION}}"
IMAGE="localhost:5000/zanbaldwin/silverblue:${TARGET}"
podman build --pull='newer' --tag="${IMAGE}" \
    --build-arg="FEDORA_VERSION=${FEDORA_VERSION}" \
    --build-arg="LINUX_VERSION=${LINUX_VERSION}" \
    --target="${TARGET}" \
    "${THIS_DIR}"
podman start 'registry' || podman run -d --name='registry' --publish='5000:5000' 'docker.io/library/registry:2'
podman push "${IMAGE}"
# Reclaim disk by dropping the untagged intermediate build-stage images (each can
# be several GB). The tagged "${IMAGE}" and pulled base images are kept.
podman image prune --force || true
rpm-ostree rebase "ostree-unverified-registry:${IMAGE}" || rpm-ostree upgrade

echo "Reboot your machine to start using the new image."
