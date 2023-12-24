#!/bin/bash

flatpak remote-add --if-not-exists flathub "https://flathub.org/repo/flathub.flatpakrepo"
flatpak remote-modify --enable flathub
flatpak update --appstream
flatpak update

flatpak install --noninteractive --assumeyes --or-update flathub \
    "com.bitwarden.desktop" \
    "org.chromium.Chromium" \
    "com.github.tchx84.Flatseal" \
    "com.mattjakeman.ExtensionManager" \
    "md.obsidian.Obsidian" \
    "org.videolan.VLC" \
    "com.visualstudio.code" \
    "us.zoom.Zoom"

if [ "$(uname -i)" == "x86_64" ]; then
    # The following Flatpaks are not available on ARM64/aarch64 architecture, as of 2023-06-02.
    flatpak install --noninteractive --assumeyes --or-update flathub \
        "com.jetbrains.CLion" \
        "com.discordapp.Discord" \
        "com.jetbrains.PhpStorm" \
        "com.skype.Client" \
        "com.slack.Slack" \
        "com.syntevo.SmartGit" \
        "com.spotify.Client"
fi
