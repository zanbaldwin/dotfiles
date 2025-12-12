sudo dnf install --assumeyes fontconfig-devel git

TOOLBOX_DIRECTORY="$(dirname "$(readlink -f -- "$0")")"
. "${TOOLBOX_DIRECTORY}/stable-version.sh"

export ALACRITTY_GIT_REPO="https://github.com/alacritty/alacritty.git"
git clone "${ALACRITTY_GIT_REPO}" --branch "$(remote_stable_version "${ALACRITTY_GIT_REPO}")" --depth=1 "/tmp/alacritty"
(cd "/tmp/alacritty"; cargo build --release --features "wayland")

mkdir -p "${HOME}/.cache/alacritty/bin" \
    "${HOME}/.cache/alacritty/etc/bash_completion.d" \
    "${HOME}/.cache/alacritty/share/pixmaps" \
    "${HOME}/.cache/alacritty/share/applications"

cp "/tmp/alacritty/target/release/alacritty" "${HOME}/.cache/alacritty/bin/alacritty"
cp "/tmp/alacritty/extra/logo/alacritty-term.svg" "${HOME}/.cache/alacritty/share/pixmaps/Alacritty.svg"
cp "/tmp/alacritty/extra/linux/Alacritty.desktop" "${HOME}/.cache/alacritty/share/applications/alacritty.desktop"
cp "/tmp/alacritty/extra/completions/alacritty.bash" "${HOME}/.cache/alacritty/etc/bash_completion.d/alacritty"

rm -rf "/tmp/alacritty"
