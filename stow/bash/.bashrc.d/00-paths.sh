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

# Standalone binaries should be put in your home directory (especially for macOS and immutable OSs like Silverblue).
add_to_path "${HOME}/bin"
# Import Cargo, and all binaries installed by it (whether part of RustLang or just written in Rust)
[ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"
