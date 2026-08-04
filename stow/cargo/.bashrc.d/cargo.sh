#!/bin/bash

# cc-rs >=1.3 wraps C builds with kache automatically when RUSTC_WRAPPER=kache
# (set in ~/.cargo/config.toml); exporting CC=kache-cc on top double-wraps as
# `kache kache-cc ...`, which kache rejects, breaking -sys crate build scripts.
