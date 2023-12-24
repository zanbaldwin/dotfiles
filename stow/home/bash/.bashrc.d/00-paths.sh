#!/bin/bash

function add_to_path() {
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

# Import Wasmer, if it's installed.
[ -s "${HOME}/.wasmer/wasmer.sh" ] && . "${HOME}/.wasmer/wasmer.sh"

# On macOS, we definitely want everything we install via Homebrew.
[ -d "/opt/homebrew/bin" ] && add_to_path "/opt/homebrew/bin"

# Next, import Cargo, and all binaries installed by it (whether part of RustLang or just written in Rust)
# We want this after Homebrew, so the latest compiled versions take precedence over Homebrew.
[ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"

# Standalone binaries should be put in your home directory (especially for macOS and immutable OSs like Silverblue).
# These are usually binaries we downloaded manually (maybe an older version in package repositories).
add_to_path "${HOME}/bin"
