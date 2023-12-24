#!/bin/bash

if [ -f "${HOME}/.cargo/env" ]; then
    # Just in case this script is being immediately after `rust.sh` without a reload.
    # shellcheck source="/dev/null"
    source "${HOME}/.cargo/env"
fi

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

rustup target add "wasm32-wasi"

mkdir -p "${HOME}/.local/share/zellij/plugins"
rm -rf /tmp/zellij*
git clone "https://github.com/imsnif/monocle.git" "/tmp/zellij-monocle" \
    && git -C "/tmp/zellij-monocle" checkout "$(zellij_stable_version "/tmp/zellij-monocle")" \
    && (cd "/tmp/zellij-monocle"; cargo build --target "wasm32-wasi" --release) \
    && cp "/tmp/zellij-monocle/target/wasm32-wasi/release/monocle.wasm" "${HOME}/.local/share/zellij/plugins/monocle.wasm" \
    && rm -rf "/tmp/zellij-monocle"
