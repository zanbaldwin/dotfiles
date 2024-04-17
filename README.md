# :wrench: Yet Another Dotfiles Repo

This dotfiles repository has been designed for use with OSTree operating systems
such as Fedora Silverblue (but also contains experimental NixOS configurations).
If you are using anything else, then you will need to read through the scripts
and configuration and figure out how to adapt them to your system.

```bash
git clone "git@github.com:zanbaldwin/dotfiles.git" "~/.dotfiles"
```

- OS Configuration
  - **Main** (work laptop) using [Fedora
    Silverblue](https://silverblue.fedoraproject.org/): customised build using
    an OCI image definition. See the [README in the `oci/` directory](./oci) for
    build and rebasing instructions.
  - **Secondary** (personal desktop) using [NixOS](https://nixos.org/):
    deterministic build using [Flakes](https://nixos.wiki/wiki/Flakes). See the
    [README in the `nixos/` directory](./nixos) for installation instructions.
- Environment Setup Scripts
  - [`toolbox/flatpak.sh`](./toolbox/flatpak.sh): install my preferred default
    applications from [Flathub](https://flathub.org).
  - [`toolbox/fonts.sh`](./toolbox/fonts.sh): extract my preferred fonts stored
    in [`fonts/`](./fonts), so I don't have to go downloading them or searching
    for them in the package manager.
  - [`toolbox/php.sh`](./toolbox/php.sh) and [`toolbox/rust.sh`](./toolbox/rust.sh):
    setup development environment [containers](https://containertoolbx.org) for,
    and tools written in, those languages.
  - [`toolbox/qmk.sh`](./toolbox/qmk.sh): setup script for customized keymap
    firmware, in [`qmk/`](./qmk), for a Corne keyboard.
  - And, **most importantly**, [`toolbox/stow.sh`](./toolbox/stow.sh): link all
    of my personal Dotfiles, organized and categorized in [`stow/`](./stow),
    into my home directory.
- Various notes, reminders and archived stuff are in [`notes/`](./notes)

> [!WARNING]
> This project makes no promises regarding backwards-compatibility. There are no
> stable releases. Things will break simply because I thought I would try
> something different.
