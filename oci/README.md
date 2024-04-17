# Fedora OCI Operating System Images

### Host your own container registry locally
Skip this step if you are planning on pushing to an official container registry
like [docker.io](https://hub.docker.com) or [ghcr.io](https://ghcr.io). Set your
`REGISTRY` environment variable appropriately.

```shell
{ \
    echo "[[registry]]"; \
    echo "location = 'localhost:5000'"; \
    echo "insecure = true"; \
} | sudo tee --append "/etc/containers/registries.conf"

podman run -d --name="registry" --publish="5000:5000" "docker.io/library/registry:2"
export REGISTRY="localhost:5000"
```

### Building your custom Operating System image
```shell
podman build \
    --file "Containerfile" \
    --tag "${REGISTRY}/zanbaldwin/silverblue:latest" \
    "${DOTFILES_DIR}/oci"
```

The default build target is `gnome`, use `--target="linux"` to use a custom build of the
Linux kernel (which has absolute no guarantees it will even build).

Specify the following build arguments (using `--build-arg="NAME=value"`) for
further customization:
- `VARIANT` (default value `silverblue`)
- `VERSION` (default value `39`)

### Push and Deploy
```shell
# Annoying that we can't re-use the one that Podman just built; will
# have to look into that further.
podman push "${REGISTRY}/zanbaldwin/silverblue:latest"
rpm-ostree rebase "ostree-unverified-registry:${REGISTRY}/zanbaldwin/silverblue:latest"
# Reboot into your custom Operating System image!
systemctl reboot
```
