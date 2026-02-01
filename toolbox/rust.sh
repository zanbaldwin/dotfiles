#!/usr/bin/env bash

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f -- "$0")")"
if [ -f "${TOOLBOX_SCRIPT_DIRECTORY}/toolbox.sh" ]; then
    source "${TOOLBOX_SCRIPT_DIRECTORY}/toolbox.sh"
fi

# Perl is required for OpenSSL to build -> openssl-sys -> zellij.
if command -v 'dnf' >'/dev/null' 2>&1; then
    # Requiring all of these seems a little excessive, when only `gcc` is required.
    # sudo dnf group install --assumeyes \
    #     'C Development Tools and Libraries' \
    #     'Development Libraries' \
    #     'Development Tools'
    sudo dnf install --assumeyes \
        'alsa-lib-devel' \
        'clang' \
        'cmake' \
        'gcc' \
        'musl-gcc' \
        'openssl-devel' \
        'perl' \
        'pkg-config'
elif command -v 'apt' >'/dev/null' 2>&1; then
    # Using Ubuntu now, use Ubuntu package manager and package names.
    sudo apt update
    sudo apt install -y \
        'build-essential' \
        'clang' \
        'cmake' \
        'musl-tools' \
        'libssl-dev' \
        'pkg-config'
fi

# Yeah, this is not good. Running an arbitrary script from the internet.
# Only doing this because Rust does not provide signatures for installing Rust in a version-agnostic way.
# shellcheck disable=SC2015
command -v 'cargo' >'/dev/null' 2>&1 && { \
    rustup update; \
} || { \
    curl --proto '=https' --tlsv1.3 -sSf 'https://sh.rustup.rs' >'/tmp/rustup.sh' && { \
        sh '/tmp/rustup.sh' -qy --no-modify-path; \
        # shellcheck source="/dev/null"
        source "${HOME}/.cargo/env"; \
    } || { echo >&2 'Error downloading RustLang installation script.'; } \
}

# Run separately instead of one command so that Cargo cleans up build files between each one.
# Kept running into /tmp ramfs running out of space on small VMs.

# Don't bother installing/compiling them again if they're already installed.
# Use `cargo install-update` to upgrade them.

# Important Rust binaries I want for *every* installation.
command -v 'bat' >'/dev/null' 2>&1                  || cargo install 'bat' --locked       # `cat` but better
command -v 'eza' >'/dev/null' 2>&1                  || cargo install 'eza' --locked       # `ls` but better
command -v 'starship' >'/dev/null' 2>&1             || cargo install 'starship' --locked  # PS1
command -v 'delta' >'/dev/null' 2>&1                || cargo install 'git-delta' --locked # Better Diffing
command -v 'onefetch' >'/dev/null' 2>&1             || cargo install 'onefetch' --locked  # Git Repository Overview
command -v 'zellij' >'/dev/null' 2>&1               || cargo install 'zellij' --locked    # Terminal Multiplexer (tmux replacement)
command -v 'atuin' >'/dev/null' 2>&1                || cargo install 'atuin' --locked     # Better Bash History
command -v 'rg' >'/dev/null' 2>&1                   || cargo install 'ripgrep' --locked   # It's just fast

# Other tools that I want to try to start using more
# Useful Rust binaries that I want on my machine, or tools I want to try to
# start using more, but I'll cancel the script about here when running in VMs.
command -v 'coreutils' >'/dev/null' 2>&1            || cargo install 'coreutils' --locked # Rusty GNU
command -v 'hyperfine' >'/dev/null' 2>&1            || cargo install 'hyperfine' --locked # Benchmarking utility, more advanced than `time`
command -v 'koji' >'/dev/null' 2>&1                 || cargo install 'koji' --locked      # Conventional Commits
command -v 'oha' >'/dev/null' 2>&1                  || cargo install 'oha' --locked       # HTTP Load Testing
command -v 'jj' >'/dev/null' 2>&1                   || cargo install 'jj-cli' --locked    # Jujutsu DVCS layered on top of Git
command -v 'sd' >'/dev/null' 2>&1                   || cargo install 'sd' --locked        # Replacement for `sed`
command -v 'hexyl' >'/dev/null' 2>&1                || cargo install 'hexyl' --locked     # Binary file viewer

# Specifically for Rust development instead of general tools
command -v 'bacon' >'/dev/null' 2>&1                || cargo install 'bacon' --locked         # Background Rust Code Checker (alternative watch TUI)
command -v 'cargo-expand' >'/dev/null' 2>&1         || cargo install 'cargo-expand' --locked  # Macro Source Code Expansion
command -v 'cargo-info' >'/dev/null' 2>&1           || cargo install 'cargo-info' --locked    # crates.io in the terminal
command -v 'tokio-console' >'/dev/null' 2>&1        || cargo install 'tokio-console' --locked # Tokio Tracing Console
command -v 'cargo-install-update' >'/dev/null' 2>&1 || cargo install 'cargo-update' --locked  # Update all installed binaries
command -v 'tree-sitter' >'/dev/null' 2>&1          || cargo install 'tree-sitter-cli' --locked

command -v 'typst' >'/dev/null' 2>&1                || cargo install 'typst-cli' --locked     # Typst
command -v 'typstyle' >'/dev/null' 2>&1             || cargo install 'typstyle' --locked      # Typst Linter/Formatter

# The following are kept for reference, but I don't think I want to use them
#command -v 'zoxide' >'/dev/null' 2>&1               || cargo install 'zoxide'                 # `cd` alternative
#command -v 'sccache' >'/dev/null' 2>&1              || cargo install 'sccache'                # Build Artifact Cache
#command -v 'cargo-wizard' >'/dev/null' 2>&1         || cargo install 'cargo-wizard' --locked  # Automatic configuration of Cargo projects
#command -v 'systemctl-tui' >'/dev/null' 2>&1        || cargo install 'systemctl-tui' --locked # SystemD TUI
#command -v 'gimoji' >'/dev/null' 2>&1               || cargo install 'gimoji' --locked        # Select an appropriate emoji to Git commits depending on what the commit does
#command -v 'gitui' >'/dev/null' 2>&1                || cargo install 'gitui' --locked         # Git TUI
#command -v 'mprocs' >'/dev/null' 2>&1               || cargo install 'mprocs' --locked        # Multi Process Runner
# Control Spotify from command line, instead of through Flatpak. Used for Eww.crates
# `secret-tool store --label='spotifyd' application rust-keyring service spotifyd username zanbaldwin`
#command -v 'spotifyd' >'/dev/null' 2>&1             || cargo install 'spotifyd' --locked --features 'dbus_keyring'
#command -v 'spt' >'/dev/null' 2>&1                  || cargo install 'spotify-tui' --locked


#if [ ! -f '/etc/NIXOS' ] && ! command -v 'nix-installer' >'/dev/null' 2>&1; then
#    # Target musl so that it can be copied onto a VM and not worry about whether
#    # the required linked-libraries are installed.
#    rustup target add 'x86_64-unknown-linux-musl'
#    # Requires unstable Tokio until they update their MSRV.
#    RUSTFLAGS='--cfg tokio_unstable' cargo install 'nix-installer' --target 'x86_64-unknown-linux-musl'
#fi

rustup target add 'wasm32-wasip2' || rustup target add 'wasm32-wasip1' || rustup target add 'wasm32-wasi'
command -v 'wasmer' >'/dev/null' 2>&1 || curl -sSfL 'https://get.wasmer.io' | bash
