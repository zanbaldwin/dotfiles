# Fedora OCI Operating System Images

### Define your settings
```bash
# Could also be "kinoite" (KDE sping), or "sericea" (Sway spin).
export VARIANT="silverblue"
# Currently, this can either be `gnome` or `hyprland`.
export WM="gnome"
# Fedora 39 is the first version to officially publish as OCI images.
export VERSION="39"
# This could be an official container registry (like "docker.io", "ghcr.io", etc).
export REGISTRY="localhost:5000"
export NAMESPACE="zanbaldwin"
# If pushed to an official container registry, should probably be repository name.
export IMAGE="silverblue"
```

### Building your custom Operating System image
```bash
podman build \
    --file "Containerfile" \
    --build-arg="VARIANT=${VARIANT}" \
    --build-arg="VERSION=${VERSION}" \
    --target="${WM}"
    --tag "${REGISTRY}/${NAMESPACE}/${IMAGE}:${VERSION}" \
    "$(pwd)"
```

### Host your own container registry locally
```bash
{ \
    echo "[[registry]]"; \
    echo "location = 'localhost:5000'"; \
    echo "insecure = true"; \
} | sudo tee --append "/etc/containers/registries.conf"

podman run -d --name="registry" --publish="5000:5000" "docker.io/library/registry:2"
```

### Push and Deploy
```bash
podman push "${REGISTRY}/${NAMESPACE}/${IMAGE}:${VERSION}"
# Annoying that we can't re-use the one that Podman just built; will have to look into that further.
rpm-ostree rebase "ostree-unverified-registry:${REGISTRY}/${NAMESPACE}/${IMAGE}:${VERSION}"
```

### Clean up
```bash
podman rm -f "registry"
podman rmi \
    "docker.io/library/registry:2" \
    "quay.io/fedora/fedora-${VARIANT}:${VERSION}" \
    "${REGISTRY}/${NAMESPACE}/${IMAGE}:${VERSION}"
```

### Reboot into your custom Operating System image!
```bash
systemctl reboot
```
