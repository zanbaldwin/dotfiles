#!/bin/bash

HYPRLAND_SCRIPTS_DIRECTORY="$(dirname "$(readlink -f "$0")")"
WALLPAPER_DIRECTORY="$(readlink -f "${HYPRLAND_SCRIPTS_DIRECTORY}/../../../../wallpaper/.local/share/wallpaper")"

if [ ! -d "${WALLPAPER_DIRECTORY}" ]; then
    echo "Directory not found: ${WALLPAPER_DIRECTORY}"
    exit 1
fi

# Technically this will fail if the file or path to the wallpaper contains a
# newline (which is allowed in POSIX).
while true; do
    find "${WALLPAPER_DIRECTORY}" -mindepth 1 -maxdepth 1 -type f | while read -r WALLPAPER_FILE; do
        swww img --sync --transition-type="grow" --transition-pos="top-left" "${WALLPAPER_FILE}"
        # Wait 15 minutes before changing the wallpaper again.
        sleep 900
    done
done
