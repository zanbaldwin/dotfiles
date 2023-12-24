# Setting Up Fedora Silverblue

Still left to figure out:
- [ ] Getting PHPStorm inside a Flatpak container to access PHP, either `toolbox` or `rpm-ostree`, using `flatpak-spawn`?
- [ ] Getting Docker Compose to work with Podman, using `podman-docker`?

## System (Immutable) Setup

### Image Layers
Check for any system updates, especially any security advisories.
```bash
rpm-ostree upgrade --check
```

Installing the full RPM Fusion repositories, not just the ones that come with Fedora base.
The non-free nVidia repositories are already enabled so maybe this can be skipped?
```bash
rpm-ostree install --idempotent \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
```

List of software to be installed:
- nVidia Graphics Drivers
- Kernel-based Virtual Machine
- PHP & Nginx (so that PHP-FPM is available as a system service)
- Other tools I want on my command line as a non-root user
```bash
rpm-ostree install --idempotent --allow-inactive \
    akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda \
    bridge-utils edk2-ovmf guestfs-tools libguestfs-tools libvirt-daemon-config-network libvirt-daemon-kvm libvirt-devel qemu-kvm virt-install virt-manager virt-top virt-viewer \
    php php-bcmath php-devel php-fpm php-gd php-mbstring php-mysqlnd php-pdo php-pear php-pgsql php-pecl-amqp php-pecl-apcu php-pecl-redis5 php-pecl-xdebug3 php-pecl-zip php-pgsql php-process php-soap php-xml nginx \
    distrobox nss-tools podman-docker tmux
```

Blacklist the _nouveau_ (non-proprietary) graphics drivers.
```bash
rpm-ostree kargs \
    --append=rd.driver.blacklist=nouveau \
    --append=modprobe.blacklist=nouveau \
    --append=nvidia-drm.modeset=1
```

### Image Update Settings
Edit `/etc/rpm-ostreed.conf` to make sure that Silverblue will automatically check for new updates.
```conf
[Daemon]
AutomaticUpdatePolicy=check
```

## User (Mutable) Setup
Software from FlatHub:

BitWarden, Chromium, CLion, Discord, Flatseal, GNOME Extension Manager,
Obsidian, PHPStorm, Skype, Slack, SmartGit, Spotify, VLC, VS Code, Zoom.

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-modify --enable flathub

flatpak install --noninteractive --assumeyes --or-update flathub \
    com.bitwarden.desktop \
    org.chromium.Chromium \
    com.jetbrains.CLion \
    com.discordapp.Discord \
    com.github.tchx84.Flatseal \
    com.mattjakeman.ExtensionManager \
    md.obsidian.Obsidian \
    com.jetbrains.PhpStorm \
    com.skype.Client \
    com.slack.Slack \
    com.syntevo.SmartGit \
    com.spotify.Client \
    org.videolan.VLC \
    com.visualstudio.code \
    us.zoom.Zoom
```

Configure GNOME Desktop
```bash
toolbox create dconf
toolbox enter dconf
bash "./toolbox/install-dconf.sh"
```

Setup PHP Environment
```bash
toolbox create php
toolbox enter php
bash "./toolbox/install-php.sh"
```

Install Rust (and Cargo, and awesome command-line tools)
```bash
toolbox create rust
toolbox enter rust
bash "./toolbox/install-rust.sh"
```

Import custom configuration from this repository.
```bash
toolbox create stow
toolbox enter stow
bash "./toolbox/install-stow.sh"
```

### Common Terminal Tools
Tools that can go in `~/bin` (the mutable version of `/usr/local/bin`)
- [`btop`](https://github.com/aristocratos/btop)
- [`composer`](https://getcomposer.org) (may be moved to `php` toolbox if I can get PHPStorm working with Flatpak)
- [`docker-compose`](https://github.com/docker/compose)
- [`duf`](https://github.com/muesli/duf)
- [`glow`](https://github.com/charmbracelet/glow)
- [`gum`](https://github.com/charmbracelet/gum)
- [`jq`](https://github.com/stedolan/jq)
- [`mkcert`](https://github.com/FiloSottile/mkcert) (see [workaround for Silverblue](https://github.com/fedora-silverblue/issue-tracker/issues/397#issuecomment-1372211636))
