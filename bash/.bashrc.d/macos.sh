#!/bin/bash

# Set PATH, MANPATH, etc., for Homebrew.
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    # Override Make 3.81 that comes as default with macOS with one that's not nearly 2 decades old..
    export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
fi
