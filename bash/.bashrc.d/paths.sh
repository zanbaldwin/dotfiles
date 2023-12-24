#!/bin/bash

# Standalone binaries should be put in your home directory (especially for macOS and immutable OSs like Silverblue).
export PATH="${HOME}/.bin:${PATH}"
# Import Cargo, and all binaries installed by it (whether part of RustLang or just written in Rust)
[ -f "${HOME}/.cargo/env" ] && . "${HOME}/.cargo/env"
