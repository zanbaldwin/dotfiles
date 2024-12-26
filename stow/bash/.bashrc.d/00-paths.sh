#!/bin/bash

function add_to_path {
    ADD="${1}"
    case ":${PATH}:" in
        *:"${ADD}":*)
            ;;
        *)
            # Prepending path in case it's to override system-wide executables.
            export PATH="${ADD}:${PATH}"
            ;;
    esac
}

# Import Custom User Executables
# Standalone binaries should be put in your home directory (especially for macOS and immutable OSs like Silverblue).
# These are usually binaries we downloaded manually (maybe an older version in package repositories).
[ -d "${HOME}/bin" ] && add_to_path "${HOME}/bin"
[ -d "${HOME}/.local/bin" ] && add_to_path "${HOME}/.local/bin"

# Import Wasmer, if it's installed.
export WASMER_DIR="${HOME}/.wasmer"
[ -s "${WASMER_DIR}/wasmer.sh" ] && source "${WASMER_DIR}/wasmer.sh"

# On macOS, we definitely want everything we install via Homebrew.
[ -d "/opt/homebrew/bin" ] && add_to_path "/opt/homebrew/bin"

# Next, import Cargo, and all binaries installed by it (whether part of RustLang or just written in Rust)
# We want this after Homebrew, so the latest compiled versions take precedence over Homebrew.
[ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"

# Make the programs installed via Nix available on the path.
# The Nix installer probably altered /etc/bashrc to do this anyway.
if [ -d "${HOME}/.local/state/nix/profile" ]; then
    export MY_NIX_PROFILE="${HOME}/.local/state/nix/profile";
    add_to_path "${MY_NIX_PROFILE}/bin";
elif [ -d "${HOME}/.nix-profile" ]; then
    EXPORT MY_NIX_PROFILE="${HOME}/.nix-profile";
    add_to_path "${MY_NIX_PROFILE}/bin";
fi
