if [ -f "${HOME}/.cargo/env" ]; then
    # Just in case this script is being immediately after `rust.sh` without a reload.
    # shellcheck source="/dev/null"
    source "${HOME}/.cargo/env"
fi

TOOLBOX_DIRECTORY="$(dirname "$(readlink -f "$0")")"
. "${TOOLBOX_DIRECTORY}/stable-version.sh"

# Zellij Plugins
zellij_stable_version() {
    GIT_DIR="${1:-$(pwd)}"
    # Fetch all tags that contain at least a MAJOR.MINOR, filtering out hyphens (alpha, beta, rc, etc), and print the latest.
    # Escape to use the original `grep` so we know what we're getting (just in case `rg` is aliased), and use PCRE2 flag.
    git -C "${GIT_DIR}" tag --list --sort="version:refname" \
        | \grep -P -e '\d+\.\d+' \
        | \grep -P -v 'alpha|ALPHA|beta|BETA|rc|RC|-' \
        | sort --version-sort \
        | tail -n1
}


TARGET="wasm32-wasip1"
rustup target add "${TARGET}"

mkdir -p "${HOME}/.local/share/zellij/plugins"
rm -rf /tmp/zellij*
git clone "https://github.com/imsnif/monocle.git" --branch "$(remote_stable_version "https://github.com/imsnif/monocle.git")" --depth=1 "/tmp/zellij-monocle" \
    && (cd "/tmp/zellij-monocle"; cargo build --target "${TARGET}" --release) \
    && cp "/tmp/zellij-monocle/target/${TARGET}/release/monocle.wasm" "${HOME}/.local/share/zellij/plugins/monocle.wasm" \
    && rm -rf "/tmp/zellij-monocle"
git clone "https://github.com/dj95/zjstatus.git" --branch "$(remote_stable_version "https://github.com/dj95/zjstatus.git")" --depth=1 "/tmp/zellij-zjstatus" \
    && (cd "/tmp/zellij-zjstatus"; cargo build --target "${TARGET}" --release) \
    && cp "/tmp/zellij-zjstatus/target/${TARGET}/release/zjstatus.wasm" "${HOME}/.local/share/zellij/plugins/zjstatus.wasm" \
    && rm -rf "/tmp/zellij-zjstatus"

# This one will likely error, as it *currently* requires downloading the `wasm32-wasi` target for the `1.72.0` toolchain.
# rustup target add --toolchain 1.72.0 wasm32-wasi
git clone "https://github.com/dj95/zj-docker.git" --branch "$(remote_stable_version "https://github.com/dj95/zj-docker.git")" --depth=1 "/tmp/zellij-docker" \
    && (cd "/tmp/zellij-docker"; cargo build --target "${TARGET}" --release) \
    && cp "/tmp/zellij-zjstatus/target/${TARGET}/release/zj-docker.wasm" "${HOME}/.local/share/zellij/plugins/docker.wasm" \
    && rm -rf "/tmp/zellij-docker"
