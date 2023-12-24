#!/bin/bash

sudo dnf group install --assumeyes \
    "C Development Tools and Libraries" \
    "Development Libraries" \
    "Development Tools"

# Yeah, this is not good. Running an arbitrary script from the internet.
# Only doing this because Rust does not provide signatures for installing Rust in a version-agnostic way.
command -v "cargo" >"/dev/null" 2>&1 && { \
    rustup update; \
} || { \
    curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" >"/tmp/rustup.sh" && { \
        sh /tmp/rustup.sh -qy --no-modify-path; \
        source "${HOME}/.cargo/env"; \
    } || { echo >&2 "Error downloading Rustlang installation script."; } \
}

cargo install \
    "bat" \
    "exa" \
    "git-delta" \
    "onefetch" \
    "starship"
