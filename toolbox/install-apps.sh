#!/bin/bash

flatpak remote-add --if-not-exists flathub "https://flathub.org/repo/flathub.flatpakrepo"
flatpak remote-modify --enable flathub

flatpak install --noninteractive --assumeyes --or-update flathub \
    "com.bitwarden.desktop" \
    "org.chromium.Chromium" \
    "com.jetbrains.CLion" \
    "com.discordapp.Discord" \
    "com.github.tchx84.Flatseal" \
    "com.mattjakeman.ExtensionManager" \
    "md.obsidian.Obsidian" \
    "com.jetbrains.PhpStorm" \
    "com.skype.Client" \
    "com.slack.Slack" \
    "com.syntevo.SmartGit" \
    "com.spotify.Client" \
    "org.videolan.VLC" \
    "com.visualstudio.code" \
    "us.zoom.Zoom"
