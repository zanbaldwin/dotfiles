#!/usr/bin/env bash

if [ -f "/run/.toolboxenv" ] && [ -f "/run/.containerenv" ]; then
    # shellcheck source="/dev/null"
    source "/run/.containerenv"
fi
