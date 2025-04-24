#!/bin/bash

# Explicitly create directories that shouldn't be made into symbolic links.
mkdir -p \
    "${HOME}/bin" \
    "${HOME}/.cargo" \
    "${HOME}/code" \
    "${HOME}/.config/autostart" \
    "${HOME}/.config/flakes" \
    "${HOME}/.config/systemd/user/default.target.wants" \
    "${HOME}/.local/share/applications" \
    "${HOME}/.ssh/conf.d" \
    "${HOME}/.ssh/keys"

if ! command -v "stow" >"/dev/null" 2>&1; then
    if command -v "dnf" >"/dev/null" 2>&1; then
        sudo dnf install --assumeyes "stow"
    elif command -v "apt-get" >"/dev/null" 2>&1; then
        # Binary "apt" exists on macOS for some reason.
        sudo apt-get install -y "stow"
    elif command -v "brew" >"/dev/null" 2>&1; then
        sudo brew install "stow"
    fi
else
    echo "GNU Stow already installed."
fi

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f "$0")")"

STOW_DIR="${TOOLBOX_SCRIPT_DIRECTORY}/../stow"
TARGET_DIR="${HOME}"

echo "Looking for packages in \"${STOW_DIR}\" to stow into \"${TARGET_DIR}...\""
if [ ! -d "${STOW_DIR}" ]; then
    echo >&2 "Error: Stow directory \"${STOW_DIR}\" not found."
    exit 1
fi

# Find all directories directly in the stow directory.
# Remove the stow directory prefix, so we're just left with the found directory name.
# `IFS=` prevents leading/trailing whitespace from getting trimmed.
# `|| [[ -n "$PACKAGE" ]]` handles the case where the last line doesn't end with a newline.
# `-r` flag in the `while` prevents backslash interpretation.
find "${STOW_DIR}" -maxdepth 1 -mindepth 1 -type 'd' | sed "s#${STOW_DIR}/##g" | while IFS= read -r PACKAGE || [ -n "${PACKAGE}" ]; do
    # Skip empty lines if `sed` somehow produces one.
    if [ -z "${PACKAGE}" ]; then
        continue
    fi
    # shellcheck disable=SC2086
    if stow --dir="${TOOLBOX_SCRIPT_DIRECTORY}/../stow" --target="${HOME}" --stow ${PACKAGE}; then
        echo "Stowed \"${PACKAGE}\" into ${HOME}..."
    else
        echo "Failed to stow \"${PACKAGE}\"!"
    fi
done
