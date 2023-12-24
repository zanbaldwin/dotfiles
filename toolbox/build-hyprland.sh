#!/bin/bash

# # xcb-errors isn't available in the Fedora repositories.
# sudo dnf install --assumeyes \
#     autoconf \
#     automake \
#     libxcb-devel \
#     xcb-proto \
#     xorg-x11-util-macros
# git clone --recursive "https://gitlab.freedesktop.org/xorg/lib/libxcb-errors" "/tmp/libxcb-errors"
# command -v "python" >"/dev/null" 2>&1 || { sudo ln -s "/usr/bin/python3" "/usr/bin/python"; }
# ( \
#     cd "/tmp/libxcb-errors"; \
#     git -C "/tmp/libxcb-errors" checkout "$(latest_stable_version)"; \
#     bash "/tmp/libxcb-errors/autogen.sh" --prefix="/usr"; \
#     sudo make install; \
# )

# # Vulkan Renderer
# sudo dnf install --assumeyes \
#     gcc-c++ \
#     glslang-devel \
#     libfontenc-devel \
#     libuuid-devel \
#     libxkbfile-devel \
#     libxcb-devel \
#     libXrandr-devel \
#     libXres-devel \
#     libXaw-devel \
#     libXcursor-devel \
#     libXcomposite-devel \
#     libXdamage-devel \
#     libXdamage-devel \
#     libXdmcp-devel \
#     libXinerama-devel \
#     libXi-devel \
#     libXtst-devel \
#     libXvMC-devel \
#     libXv-devel \
#     libXxf86vm-devel \
#     libXScrnSaver-devel \
#     libICE-devel \
#     libSM-devel \
#     mesa-libGL-devel \
#     mingw64-vulkan-headers \
#     mingw64-vulkan-loader \
#     ninja-build \
#     pip \
#     vulkan-headers \
#     vulkan-loader-devel \
#     xcb-util-devel \
#     xcb-util-image-devel \
#     xcb-util-keysyms-devel \
#     xcb-util-renderutil-devel \
#     xcb-util-wm-devel \
#     xkeyboard-config-devel \
#     xorg-x11-xtrans-devel
# pip install \
#     conan \
#     setuptools \
#     wheel
# git clone --recursive "https://github.com/inexorgame/vulkan-renderer" "/tmp/vulkan-renderer"
# (cd "/tmp/vulkan-renderer"; cmake . -Bbuild -D'CMAKE_BUILD_TYPE=Debug' -G'Ninja' && ninja -C build)

# Hyprland
# Want the latest versions of dependencies.
sudo dnf upgrade --assumeyes
sudo dnf install --assumeyes --allow-inactive \
    cairo-devel \
    cmake \
    cpio \
    gcc-c++ \
    git \
    hwdata-devel \
    libavutil-free-devel \
    libavcodec-free-devel \
    libavformat-free-devel \
    libdisplay-info-devel \
    libdrm-devel \
    libinput-devel \
    libseat-devel \
    libxcb-devel \
    libxkbcommon-devel \
    libX11-devel \
    make \
    mesa-libEGL-devel \
    mesa-libgbm-devel \
    meson \
    ninja-build \
    pango-devel \
    pixman-devel \
    systemd-devel \
    wayland-devel \
    wayland-protocols-devel \
    wlroots-devel \
    xcb-util-renderutil-devel \
    xcb-util-wm-devel \
    xorg-x11-server-Xwayland-devel

git clone --recursive "https://github.com/hyprwm/Hyprland.git" "${HOME}/.hyprland"
git -C "${HOME}/.hyprland" checkout "$(latest_stable_version "${HOME}/.hyprland")"
# We want to build inside a toolbox, but install to the host system.
# Prefix with a directory that's available both inside and outside.
(cd "${HOME}/.hyprland"; make install PREFIX="${HOME}/.hyprland-build")

rm -rf \
    "${HOME}/.hyprland"
