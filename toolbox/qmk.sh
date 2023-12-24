#!/bin/bash

KEYBOARD="splitkb/aurora/corne"
REVISION="rev1"
KEYMAP_NAME="zanbaldwin"

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"
QMK_FIRMWARE_DIRECTORY="${HOME}/.local/share/qmk"

sudo dnf upgrade --assumeyes
sudo dnf install --assumeyes git python3-pip
python3 -m pip install --user qmk
qmk setup --home "${QMK_FIRMWARE_DIRECTORY}" --yes
qmk config user.keyboard="${KEYBOARD}/${REVISION}"
qmk config user.keymap="${KEYMAP_NAME}"
mkdir -p "${QMK_FIRMWARE_DIRECTORY}/keyboards/${KEYBOARD}/keymaps"
ln -s "${TOOLBOX_SCRIPT_DIRECTORY}/../qmk" "${QMK_FIRMWARE_DIRECTORY}/keyboards/${KEYBOARD}/keymaps/${KEYMAP_NAME}"
echo "ln -s '${TOOLBOX_SCRIPT_DIRECTORY}/../qmk' '${QMK_FIRMWARE_DIRECTORY}/keyboards/${KEYBOARD}/keymaps/${KEYMAP_NAME}'"

echo ""
echo 'Container is now set up and ready for "qmk compile" and "qmk flash" commands.'
