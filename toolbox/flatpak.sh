#!/bin/bash

flatpak remote-add --if-not-exists flathub "https://flathub.org/repo/flathub.flatpakrepo"
flatpak remote-modify --enable flathub
flatpak update --appstream
flatpak update

# Chromium/Chrome is fucky on Hyprland/Wayland. Firefox is much more stable.
# However, the Firefox from Fedora's repositories isn't able to play media on
# sites like Twitter, and the Firefox from Flathub's repositories doesn't
# respect the system-wide trust store so development certificates from MkCert
# don't work. Use the non-Flatpak version of Firefox that comes with the system.

flatpak install --noninteractive --assumeyes --or-update flathub \
    "com.bitwarden.desktop" \
    "com.mongodb.Compass" \
    "com.github.tchx84.Flatseal" \
    "com.mattjakeman.ExtensionManager" \
    "org.freedesktop.Platform.ffmpeg-full" \
    "org.videolan.VLC" \
    "com.visualstudio.code"

# The following Flatpaks are not available on ARM64/aarch64 architecture, as of 2023-06-02.
flatpak install --noninteractive --assumeyes --or-update flathub \
    "com.discordapp.Discord" \
    "com.jetbrains.PhpStorm" \
    "com.skype.Client" \
    "com.slack.Slack" \
    "com.syntevo.SmartGit" \
    "com.spotify.Client"

# Notes:
# ======

# PHPStorm version 2023.1.3 is borked.
# Disable `ide.browser.jcef.sandbox.enable` in PHPStorm's registry.
# See https://youtrack.jetbrains.com/issue/IDEA-317347/After-last-flatpak-update-idea-crashed#focus=Comments-27-7253679.0-0

# To continue using a fallback license version of PHPStorm:
# - Figure out the commit of the version you want to use (eg, acf67cd4d for v2022.3.3)
#   `flatpak remote-info --log <remote> <app-id>`
# - Downgrade the application by setting it to that commit
#   `flatpak update --commit=<commit> <app-id>`
# - Then mask the appliation from updates so it remains at that version
#   `flatpak mask <app-id>`
