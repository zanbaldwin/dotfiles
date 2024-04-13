#!/usr/bin/env bash

nix profile install \
    "nixpkgs#alejandra" \
    "nixpkgs#deadnix" \
    "nixpkgs#gcc" \
    "nixpkgs#go" \
    "nixpkgs#luarocks" \
    "nixpkgs#neovim" \
    "nixpkgs#php83" \
    "nixpkgs#statix"
