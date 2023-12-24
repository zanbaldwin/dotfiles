#!/bin/bash

sudo dnf group install --assumeyes \
    "C Development Tools and Libraries" \
    "Development Libraries" \
    "Development Tools"

sudo dnf install --assumeyes \
    "cmake" \
    "fontconfig-devel" \
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

# Important Rust binaries I want for *every* installation.
cargo install "sccache"                                      # Build Artifact Cache
cargo install --config="rustc-wrapper='sccache'" "bat"       # `cat` but better
cargo install --config="rustc-wrapper='sccache'" "exa"       # `ls` but better
cargo install --config="rustc-wrapper='sccache'" "starship"  # PS1

# Useful Rust binaries that I want on my machine, but I'll cancel the script about here when running in VMs.
cargo install --config="rustc-wrapper='sccache'" "coreutils" # Rusty GNU
cargo install --config="rustc-wrapper='sccache'" "git-delta" # Better Diffing
cargo install --config="rustc-wrapper='sccache'" "mprocs"    # Multi Process Runner
cargo install --config="rustc-wrapper='sccache'" "onefetch"  # Git Repository Overview
cargo install --config="rustc-wrapper='sccache'" "ripgrep"   # It's just fast
cargo install --config="rustc-wrapper='sccache'" "zellij"    # Terminal Multiplexer (tmux replacement)
if [[ "${OSTYPE}" == "linux-gnu"* ]]; then
    # Alacritty on macOS is poopy. Only install on Linux.
    # iTerm2 is the best you're going to get for macOS and that's still shit.
    cargo install "alacritty";
fi

# The following need more testing on Linux. See `stow/bash/.bashrc.d/directories.sh`.
cargo install --config="rustc-wrapper='sccache'" "broot"     # Terminal directory browser
cargo install --config="rustc-wrapper='sccache'" "zoxide"    # `cd` alternative

# Specifically for Rust development instead of general tools
cargo install --config="rustc-wrapper='sccache'" "bacon"         # Background Rust Code Checker (alternative watch TUI)
cargo install --config="rustc-wrapper='sccache'" "cargo-expand"  # Macro Source Code Expansion
cargo install --config="rustc-wrapper='sccache'" "cargo-info"    # crates.io in the terminal
cargo install --config="rustc-wrapper='sccache'" "tokio-console" # Tokio Tracing Console

curl -sSfL "https://get.wasmer.io" | bash
