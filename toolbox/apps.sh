#!/bin/bash

flatpak remote-add --if-not-exists flathub "https://flathub.org/repo/flathub.flatpakrepo"
flatpak remote-modify --enable flathub
flatpak update --appstream
flatpak update

# Chromium/Chrome is fucky on Hyprland/Wayland. Firefox is much more stable.
# Install the Firefox Flatpak from Fedora's repositories, otherwise the system
# trust store will not be mounted into the Flatpak and Firefox will not trust
# MkCert certificates for local development.
flatpak install --noninteractive --assumeyes --or-update fedora \
    "org.mozilla.Firefox"
flatpak install --noninteractive --assumeyes --or-update flathub \
    "com.bitwarden.desktop" \
    "com.github.tchx84.Flatseal" \
    "com.mattjakeman.ExtensionManager" \
    "md.obsidian.Obsidian" \
    "org.videolan.VLC" \
    "com.visualstudio.code"

# The following Flatpaks are not available on ARM64/aarch64 architecture, as of 2023-06-02.
flatpak install --noninteractive --assumeyes --or-update flathub \
    "com.discordapp.Discord" \
    "com.jetbrains.PhpStorm" \
    "com.skype.Client" \
    "com.slack.Slack" \
    "com.syntevo.SmartGit" \
    "com.spotify.Client" \
    "us.zoom.Zoom"

# Notes:
# ======

# PHPStorm version 2023.1.3 is borked.
# Disable `ide.browser.jcef.sandbox.enable` in PHPStorm's registry.
# See https://youtrack.jetbrains.com/issue/IDEA-317347/After-last-flatpak-update-idea-crashed#focus=Comments-27-7253679.0-0
