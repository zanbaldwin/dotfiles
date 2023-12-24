#!/bin/bash

KEYBOARD="splitkb/aurora/corne"
REVISION="rev1"
KEYMAP_NAME="zanbaldwin"

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"
QMK_FIRMWARE_DIRECTORY="${HOME}/.local/share/qmk"

sudo dnf upgrade --assumeyes
sudo dnf install --assumeyes arm-none-eabi-gcc arm-none-eabi-newlib gcc git make

# Install QMK
command -v "qmk" >"/dev/null" 2>&1 || python3 -m pip install --user qmk
if [ ! -d "${QMK_FIRMWARE_DIRECTORY}" ]; then
    qmk setup --home "${QMK_FIRMWARE_DIRECTORY}" --yes
fi

# Link custom keymap.
if [ ! -L "${QMK_FIRMWARE_DIRECTORY}/keyboards/${KEYBOARD}/keymaps/${KEYMAP_NAME}" ]; then
    mkdir -p "${QMK_FIRMWARE_DIRECTORY}/keyboards/${KEYBOARD}/keymaps"
    ln -s "${TOOLBOX_SCRIPT_DIRECTORY}/../qmk" "${QMK_FIRMWARE_DIRECTORY}/keyboards/${KEYBOARD}/keymaps/${KEYMAP_NAME}"
fi

# Configure QMK to use custom keyboard configuration.
qmk config user.keyboard="${KEYBOARD}/${REVISION}"
qmk config user.keymap="${KEYMAP_NAME}"

echo ""
echo 'Container is now set up and ready for "qmk compile" and "qmk flash" commands.'
