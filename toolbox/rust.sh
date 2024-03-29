#!/bin/bash

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"
if [ -f "${TOOLBOX_SCRIPT_DIRECTORY}/toolbox.sh" ]; then
    source "${TOOLBOX_SCRIPT_DIRECTORY}/toolbox.sh"
fi

# Requiring all of these seems a little excessive, when only `gcc` is required.
# sudo dnf group install --assumeyes \
#     "C Development Tools and Libraries" \
#     "Development Libraries" \
#     "Development Tools"

# Perl is required for OpenSSL to build -> openssl-sys -> zellij.
sudo dnf install --assumeyes \
    "alsa-lib-devel" \
    "clang" \
    "cmake" \
    "gcc" \
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

# Don't bother installing/compiling them again if they're already installed.
# Use `cargo install-update` to upgrade them.

# Important Rust binaries I want for *every* installation.
command -v "bat" >"/dev/null" 2>&1                  || cargo install "bat"       # `cat` but better
command -v "eza" >"/dev/null" 2>&1                  || cargo install "eza"       # `ls` but better
command -v "starship" >"/dev/null" 2>&1             || cargo install "starship"  # PS1
command -v "delta" >"/dev/null" 2>&1                || cargo install "git-delta" # Better Diffing
command -v "onefetch" >"/dev/null" 2>&1             || cargo install "onefetch"  # Git Repository Overview
command -v "zellij" >"/dev/null" 2>&1               || cargo install "zellij"    # Terminal Multiplexer (tmux replacement)
command -v "atuin" >"/dev/null" 2>&1                || cargo install "atuin"     # Better Bash History

# Other tools that I want to try to start using more
command -v "gimoji" >"/dev/null" 2>&1               || cargo install "gimoji"        # Select an appropriate emoji to Git commits depending on what the commit does
command -v "gitui" >"/dev/null" 2>&1                || cargo install "gitui"         # Git TUI
command -v "oha" >"/dev/null" 2>&1                  || cargo install "oha"           # HTTP Load Testing
command -v "jj" >"/dev/null" 2>&1                   || cargo install "jj-cli"        # Jujutsu DVCS layered on top of Git
command -v "sd" >"/dev/null" 2>&1                   || cargo install "sd"            # Replacement for `sed`
command -v "hyperfine" >"/dev/null" 2>&1            || cargo install "hyperfine"     # Benchmarking utility, more advanced than `time`
command -v "hexyl" >"/dev/null" 2>&1                || cargo install "hexyl"         # Binary file viewer

# Useful Rust binaries that I want on my machine, but I'll cancel the script
# about here when running in VMs.
command -v "coreutils" >"/dev/null" 2>&1            || cargo install "coreutils" # Rusty GNU
command -v "mprocs" >"/dev/null" 2>&1               || cargo install "mprocs"    # Multi Process Runner
command -v "rg" >"/dev/null" 2>&1                   || cargo install "ripgrep"   # It's just fast

# Control Spotify from command line, instead of through Flatpak. Used for Eww.
# `secret-tool store --label='spotifyd' application rust-keyring service spotifyd username zanbaldwin`
command -v "spotifyd" >"/dev/null" 2>&1             || cargo install "spotifyd" --features "dbus_keyring"
command -v "spt" >"/dev/null" 2>&1                  || cargo install "spotify-tui"

# Specifically for Rust development instead of general tools
command -v "bacon" >"/dev/null" 2>&1                || cargo install "bacon"         # Background Rust Code Checker (alternative watch TUI)
command -v "cargo-expand" >"/dev/null" 2>&1         || cargo install "cargo-expand"  # Macro Source Code Expansion
command -v "cargo-info" >"/dev/null" 2>&1           || cargo install "cargo-info"    # crates.io in the terminal
command -v "tokio-console" >"/dev/null" 2>&1        || cargo install "tokio-console" # Tokio Tracing Console
command -v "cargo-install-update" >"/dev/null" 2>&1 || cargo install "cargo-update"  # Update all installed binaries
command -v "cargo-wizard" >"/dev/null" 2>&1         || cargo install "cargo-wizard"  # Automatic configuration of Cargo projects

# For NVim
command -v "btm" >"/dev/null" 2>&1                  || cargo install "bottom"
command -v "tree-sitter" >"/dev/null" 2>&1          || cargo install "tree-sitter-cli"

# The following are kept for reference, but I don't think I want to use them
#cargo install "zoxide"    # `cd` alternative
#cargo install "sccache"   # Build Artifact Cache

command -v "wasmer" >"/dev/null" 2>&1               || curl -sSfL "https://get.wasmer.io" | bash
