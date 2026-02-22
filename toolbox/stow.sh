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
    "${HOME}/.ssh/keys" \
    "${HOME}/.dotfiles/stow/vscode/.var/app/com.visualstudio.code/config/Code"

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

# Find all directories directly in the stow directory.
# Remove the stow directory prefix, so we're just left with the found directory name.
# `IFS=` prevents leading/trailing whitespace from getting trimmed.
# `|| [[ -n "$PACKAGE" ]]` handles the case where the last line doesn't end with a newline.
# `-r` flag in the `while` prevents backslash interpretation.
stow_packages() {
    local SOURCE_DIR="${1}"
    local TARGET_DIR="${2}"
    if [ ! -d "${SOURCE_DIR}" ] || [ ! -d "${TARGET_DIR}" ]; then
        echo >&2 "Cannot stow packages to or from non-existent directories.";
        return 1;
    fi

    find "${SOURCE_DIR}" -maxdepth 1 -mindepth 1 -type 'd' | sed "s#${SOURCE_DIR}/##g" | while IFS= read -r PACKAGE || [ -n "${PACKAGE}" ]; do
        # Skip empty lines if `sed` somehow produces one.
        if [ -z "${PACKAGE}" ]; then
            continue
        fi
        # shellcheck disable=SC2086
        if stow --dir="${SOURCE_DIR}" --target="${TARGET_DIR}" --stow "${PACKAGE}"; then
            echo "Stowed \"${PACKAGE}\" into ${TARGET_DIR}..."
        else
            echo >&2 "Failed to stow \"${PACKAGE}\"!"
        fi
    done
    echo "Stow complete."
}

TOOLBOX_SCRIPT_DIRECTORY="$(dirname "$(readlink -f -- "$0")")"
stow_packages "${TOOLBOX_SCRIPT_DIRECTORY}/../stow" "${HOME}"
stow_packages "${TOOLBOX_SCRIPT_DIRECTORY}/../shell" "${HOME}"
