# Setting Up Fedora Silverblue

## System (Immutable) Setup

### Image Update Settings
Edit `/etc/rpm-ostreed.conf` to include the following configuration settings. This will automatically pull new/updated images when they are available and apply them to the tree, ready to use when you next reboot the system.
```conf
[Daemon]
AutomaticUpdatePolicy=stage
[Experimental]
StageDeployments=yes
```

### Image Layers
Installing the full RPM Fusion repositories, not just the ones that come with Fedora base.
```bash
rpm-ostree install --idempotent \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
```

Install nVidia drivers.
```bash
rpm-ostree install --idempotent \
    akmod-nvidia \
    xorg-x11-drv-nvidia \
    xorg-x11-drv-nvidia-cuda
```

Blacklist the _nouveau_ (non-proprietary) ones.
```bash
rpm-ostree kargs \
    --append=rd.driver.blacklist=nouveau \
    --append=modprobe.blacklist=nouveau \
    --append=nvidia-drm.modeset=1
```

List of software to be installed:
- Build Essential (Development Tool & Libraries)
- Kernel-based Virtual Machine
- PHP & Nginx
- Other tools I want on my command line as a non-root user
```bash
rpm-ostree install --idempotent \
    autoconf automake binutils bison gcc gcc-c++ gdb glibc-devel libtool make pkgconf strace byacc ccache cscope ctags elfutils indent ltrace perf valgrind ElectricFence astyle cbmc check cmake coan cproto insight nasm pscan python3-scons remake scorep splint yasm zzuf \
    virt-install libvirt-daemon-config-network libvirt-daemon-kvm qemu-kvm virt-manager virt-viewer guestfs-tools libguestfs-tools python3-libguestfs virt-top bridge-utils libvirt-devel edk2-ovmf \
    php php-bcmath php-devel php-gd php-imap php-mbstring php-mysqlnd php-pdo php-pear php-pgsql php-pecl-amqp php-pecl-apcu php-pecl-redis5 php-pecl-xdebug3 php-pecl-zip php-pgsql php-process php-soap php-xml nginx \
    distrobox neofetch ncdu shellcheck stow tmux
```

## User (Mutable) Setup
Software from official Fedora Repositories:
- Dconf Editor (`ca.desrt.dconf-editor`)

Software from FlatHub:
- BitWarden (`com.bitwarden.desktop`)
- Chromium (`org.chromium.Chromium`)
- CLion (`com.jetbrains.CLion`)
- Discord (`com.discordapp.Discord`)
- Flatseal (`com.github.tchx84.Flatseal`)
- GNOME Extension Manager (`com.mattjakeman.ExtensionManager`)
- Obsidian (`md.obsidian.Obsidian`)
- PHPStorm (`com.jetbrains.PhpStorm`)
- Skype (`com.skype.Client`)
- Slack (`com.slack.Slack`)
- SmartGit (`com.syntevo.SmartGit`)
- Spotify (`com.spotify.Client`)
- VLC (`org.videolan.VLC`)
- VS Code (`com.visualstudio.code`)
- Zoom (`us.zoom.Zoom`)

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --noninteractive fedora  applications-fedora.list
flatpak install --noninteractive flathub applications-flathub.list
```

Configure GNOME Desktop
```bash
# Now that Dconf is installed:
dconf write "/org/gnome/desktop/input-sources/xkb-options" "['caps:swapescape']"
dconf write "/org/gnome/desktop/calendar/show-weekdate" "false"
dconf write "/org/gnome/desktop/interface/clock-show-weekday" "true"
dconf write "/org/gnome/desktop/wm/preferences/button-layout" "appmenu:minimize,maximize,close"
dconf write "/org/gnome/system/location/enabled" "false"
```

Install Rust (and Cargo)
```bash
# Yeah, this is not good. Running an arbitrary script from the internet.
# Only doing this because Rust does not provide signatures for installing Rust in a version-agnostic way.
command -v "cargo" >/dev/null 2>&1 && { \
    rustup update; \
} || { \
    curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" > "/tmp/rustup.sh" && { \
        sh /tmp/rustup.sh -qy --no-modify-path; \
        source "${HOME}/.cargo/env"; \
    } || { echo >&2 "Error downloading Rustlang installation script."; } \
}
```

Install Awesome Command-line Tools from Crates
```bash
# Install Tools from Rustland/Crates
# This requires build-essential tools, so must be done after system/rpm-ostree.
command -v "cargo" >/dev/null 2>&1 && { \
    cargo install bat; \
    cargo install exa; \
    cargo install git-delta; \
    cargo install onefetch; \
    cargo install starship; \
}
```

### Common Terminal Tools
Tools that can go in `~/.bin` (the mutable version of `/usr/local/bin`)
- [`btop`](https://github.com/aristocratos/btop)
- [`composer`](https://getcomposer.org)
- `duf`

## Toolboxes

### Tweaks
If something hasn't been configured using Dconf and you don't know the path, use GNOME Tweaks instead.
Useful for setting system fonts.

```bash
toolbox create tweaks
toolbox enter tweaks
sudo dnf install gnome-tweaks
gnome-tweaks
```


