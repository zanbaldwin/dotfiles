#!/bin/bash

# Requiring all of these seems a little excessive, when only `gcc` is required.
# sudo dnf group install --assumeyes \
#     "C Development Tools and Libraries" \
#     "Development Libraries" \
#     "Development Tools"

# Perl is required for OpenSSL to build -> openssl-sys -> zellij.
sudo dnf install --assumeyes \
    "alsa-lib-devel" \
    "cmake" \
    "gcc" \
    "git" \
    "openssl-devel" \
    "perl" \
    "pkg-config"

# Yeah, this is not good. Running an arbitrary script from the internet.
# Only doing this because Rust does not provide signatures for installing Rust in a version-agnostic way.
# shellcheck disable=SC2015
command -v "cargo" >"/dev/null" 2>&1 && { \
    rustup update; \
} || { \
    curl --proto "=https" --tlsv1.2 -sSf "https://sh.rustup.rs" >"/tmp/rustup.sh" && { \
        sh /tmp/rustup.sh -qy --no-modify-path; \
        # shellcheck source="/dev/null"
        source "${HOME}/.cargo/env"; \
    } || { echo >&2 "Error downloading RustLang installation script."; } \
}

# Run separately instead of one command so that Cargo cleans up build files between each one.
# Kept running into /tmp ramfs running out of space on small VMs.

# Important Rust binaries I want for *every* installation.
cargo install "bat"       # `cat` but better
cargo install "exa"       # `ls` but better
cargo install "starship"  # PS1
cargo install "git-delta" # Better Diffing
cargo install "onefetch"  # Git Repository Overview
cargo install "zellij"    # Terminal Multiplexer (tmux replacement)
cargo install "atuin"         # Better Bash History

# Other tools that I want to try to start using more
cargo install "gimoji"        # Select an appropriate emoji to Git commits depending on what the commit does
cargo install "gitui"         # Git TUI
cargo install "oha"           # HTTP Load Testing

# Useful Rust binaries that I want on my machine, but I'll cancel the script
# about here when running in VMs.
cargo install "coreutils" # Rusty GNU
cargo install "mprocs"    # Multi Process Runner
cargo install "ripgrep"   # It's just fast

# Control Spotify from command line, instead of through Flatpak. Used for Eww.
# `secret-tool store --label='spotifyd' application rust-keyring service spotifyd username zanbaldwin`
cargo install "spotifyd" --features "dbus_keyring"
cargo install "spotify-tui"

# Specifically for Rust development instead of general tools
cargo install "bacon"         # Background Rust Code Checker (alternative watch TUI)
cargo install "cargo-expand"  # Macro Source Code Expansion
cargo install "cargo-info"    # crates.io in the terminal
cargo install "tokio-console" # Tokio Tracing Console
cargo install "cargo-update"  # Update all installed binaries

# The following are kept for reference, but I don't think I want to use them
#cargo install "zoxide"    # `cd` alternative
#cargo install "sccache"   # Build Artifact Cache

curl -sSfL "https://get.wasmer.io" | bash
