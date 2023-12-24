# Setting Up Fedora Silverblue

Still left to figure out:
- [x] Getting PHPStorm inside a Flatpak container to access PHP, either `toolbox` or `rpm-ostree`, using `flatpak-spawn`?
  (must give PHPStorm Flatpak container access to `/tmp`)
- [ ] Getting Docker Compose to work with Podman, using `podman-docker`?

## System (Immutable) Setup

### Image Update Settings
Edit `/etc/rpm-ostreed.conf` to make sure that Silverblue will automatically check for new updates.
```conf
[Daemon]
AutomaticUpdatePolicy=check
```

Check for any system updates, especially any security advisories.
```bash
rpm-ostree upgrade --check
```

### Image Layers

List of software to be installed, and blacklist the _nouveau_ (non-proprietary) graphics drivers:
- nVidia Graphics Drivers
- Kernel-based Virtual Machine
- Other tools I want on my command line as a non-root user

> Certain software repositories aren't available for ARM64/aarch64 architecture. Go to Software
> &rarr; Software Repositories, and disable:
> - `phracek-PyCharm`
> - `rpmfusion-nonfree-steam`

```bash
rpm-ostree kargs \
    --append=rd.driver.blacklist=nouveau \
    --append=modprobe.blacklist=nouveau \
    --append=nouveau.modeset=0 \
    --append=nvidia.modeset=1 \
    --append=nvidia-drm.modeset=1
systemctl reboot

rpm-ostree install --idempotent --allow-inactive \
    akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda \
    bridge-utils edk2-ovmf guestfs-tools qemu-kvm virt-install virt-manager virt-top \
    distrobox ncdu nss-tools podman-docker tlp tlp-rdw tmux \
    libdisplay-info
systemctl reboot
```

Enable services and modify user groups.
```bash
bash "${DOTFILES}/toolbox/enable-services.sh"
```

## User (Mutable) Setup

Install software from Flathub: _BitWarden, Chromium, CLion, Discord, Flatseal,
GNOME Extension Manager, Obsidian, PHPStorm, Skype, Slack, SmartGit, Spotify,
VLC, VS Code, Zoom._

> Don't forget to allow PHPStorm access to `/tmp` via Flatseal.

```bash
bash "${DOTFILES}/toolbox/install-apps.sh"
```

Configure GNOME Desktop
```bash
bash "${DOTFILES}/toolbox/setup-gnome.sh"
```

Install Rust (and Cargo, and awesome command-line tools). _Run this before `stow`
since custom configuration references binaries installed in via Rust._
```bash
toolbox create rust
toolbox run --container="rust" bash "${DOTFILES}/toolbox/install-rust.sh"
```

Import custom configuration from this repository.
```bash
toolbox create stow
toolbox run --container="stow" bash "${DOTFILES}/toolbox/stow-config.sh"
toolbox rm -f stow
```

Setup PHP Environment
```bash
toolbox create php
toolbox run --container="php" bash "${DOTFILES}/toolbox/install-php.sh"
```

Setup Hyprland WM
```bash
toolbox create hyprland
toolbox run --container="hyprland" bash "${DOTFILES}/toolbox/build-hyprland.sh"
toolbox rm -f hyprland
sudo rsync --archive --whole-file "${HOME}/.hyprland-build/" "/usr/local/"
rm -rf "${HOME}/.hyprland-build"
# Instruct Fedora to load dynamically-linked libraries from "/usr/local/lib".
echo "/usr/local/lib" | sudo tee "/etc/ld.so.conf.d/libwlroots.conf"
sudo ldconfig
```

### Common Terminal Tools
Tools that can go in `~/bin` (the user-mutable version of `/usr/bin`)
- [`btop`](https://github.com/aristocratos/btop)
- [`docker-compose`](https://github.com/docker/compose)
- [`duf`](https://github.com/muesli/duf)
- [`glow`](https://github.com/charmbracelet/glow)
- [`gum`](https://github.com/charmbracelet/gum)
- [`jq`](https://github.com/stedolan/jq)
- [`mkcert`](https://github.com/FiloSottile/mkcert)

### Fonts
Download the following [Nerd Fonts](https://www.nerdfonts.com/font-downloads), extract the Zip files, and move `/.*Complete\.(ttf|otf)$/` into `~/.local/share/fonts`:
- BitstreamVeraSansMono
- Caskaydia Cove
- FiraCode
- JetBrainsMono
- Meslo
- RobotoMono
- UbuntuMono

```bash
sudo fc-cache -f -v
```
