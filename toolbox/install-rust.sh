#!/bin/bash

sudo dnf group install --assumeyes \
    "C Development Tools and Libraries" \
    "Development Libraries" \
    "Development Tools"

sudo dnf install --assumeyes \
    "cmake" \
    "mold"

# Yeah, this is not good. Running an arbitrary script from the internet.
# Only doing this because Rust does not provide signatures for installing Rust in a version-agnostic way.
command -v "cargo" >"/dev/null" 2>&1 && { \
    rustup update; \
} || { \
    curl --proto "=https" --tlsv1.2 -sSf "https://sh.rustup.rs" >"/tmp/rustup.sh" && { \
        sh /tmp/rustup.sh -qy --no-modify-path; \
        source "${HOME}/.cargo/env"; \
    } || { echo >&2 "Error downloading RustLang installation script."; } \
}

# Run separately instead of one command so that Cargo cleans up build files between each one.
# Kept running into /tmp ramfs running out of space on small VMs.
if [[ "${OSTYPE}" == "linux-gnu"* ]]; then
    # Alacritty on macOS is poopy. Only install on Linux.
    # iTerm2 is the best you're going to get for macOS and that's still shit.
    cargo install "alacritty";
fi
cargo install "bat"       # `cat` but better
cargo install "coreutils" # Rusty GNU
cargo install "exa"       # `ls` but better
cargo install "git-delta" # Better Diffing
cargo install "mprocs"    # Multi Process Runner
cargo install "onefetch"  # Git Repository Overview
cargo install "ripgrep"   # It's just fast
cargo install "starship"  # PS1
cargo install "zellig"    # Terminal Multiplexer (tmux replacement)

# The following need more testing on Linux. See `stow/bash/.bashrc.d/directories.sh`.
cargo install "broot"     # Terminal directory browser
cargo install "zoxide"    # `cd` alternative

# Specifically for Rust development instead of general tools
cargo install "bacon"         # Background Rust Code Checker (alternative watch TUI)
cargo install "cargo-expand"  # Macro Source Code Expansion
cargo install "cargo-info"    # crates.io in the terminal
cargo install "sccache"       # Build Artifact Cache
cargo install "tokio-console" # Tokio Tracing Console

curl -sSfL "https://get.wasmer.io" | bash
