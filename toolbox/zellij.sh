#!/bin/bash

# Zellij Plugins
zellij_stable_version() {
    GIT_DIR="${1:-$(pwd)}"
    # Fetch all tags that contain at least a MAJOR.MINOR, filtering out hyphens (alpha, beta, rc, etc), and print the latest.
    git -C "${GIT_DIR}" tag --list --sort="version:refname" \
        | rg -e '\d+\.\d+' \
        | rg -v 'alpha|ALPHA|beta|BETA|rc|RC|-' \
        | sort --version-sort \
        | tail -n1
}

rustup target add "wasm32-wasi"

mkdir -p "${HOME}/.local/share/zellij/plugins"
rm -rf /tmp/zellij*
git clone "https://github.com/karimould/zellij-forgot.git" "/tmp/zellij-forgot" \
    && git -C "/tmp/zellij-forgot" checkout "$(zellij_stable_version "/tmp/zellij-forgot")" \
    && (cd "/tmp/zellij-forgot"; cargo build --target "wasm32-wasi" --release) \
    && cp "/tmp/zellij-forgot/target/wasm32-wasi/release/zellij_forgot.wasm" "${HOME}/.local/share/zellij/plugins/forgot.wasm" \
    && rm -rf "/tmp/zellij-forgot"

git clone "https://github.com/rvcas/room.git" "/tmp/zellij-room" \
    && git -C "/tmp/zellij-room" checkout "$(zellij_stable_version "/tmp/zellij-room")" \
    && (cd "/tmp/zellij-room"; cargo build --target "wasm32-wasi" --release) \
    && cp "/tmp/zellij-room/target/wasm32-wasi/release/room.wasm" "${HOME}/.local/share/zellij/plugins/room.wasm" \
    && rm -rf "/tmp/zellij-room"

git clone "https://github.com/imsnif/monocle.git" "/tmp/zellij-monocle" \
    && git -C "/tmp/zellij-monocle" checkout "$(zellij_stable_version "/tmp/zellij-monocle")" \
    && (cd "/tmp/zellij-monocle"; cargo build --target "wasm32-wasi" --release) \
    && cp "/tmp/zellij-monocle/target/wasm32-wasi/release/monocle.wasm" "${HOME}/.local/share/zellij/plugins/monocle.wasm" \
    && rm -rf "/tmp/zellij-monocle"

# Perhaps, https://github.com/dj95/zjstatus?
