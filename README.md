# :wrench: Yet Another Dotfiles Repo

This dotfiles repository has been designed for use with OSTree operating systems
such as Fedora Silverblue.
If you are using anything else, then you will need to read through the scripts
and configuration and figure out how to adapt them to your system.

```bash
git clone "git@github.com:zanbaldwin/dotfiles.git" "~/.dotfiles"
```

- Silverblue Setup/Upgrade: `bash oci/upgrade.sh`
- Environment Setup Scripts (run all of these from inside a Toolbox):
  - [`toolbox/dconf.sh`](./toolbox/dconf.sh): configure GNOME defaults
  - [`toolbox/fonts.sh`](./toolbox/fonts.sh): install Nerd Fonts
  - [`toolbox/ghostty.sh`](./toolbox/ghostty.sh): compile and install Ghostty terminal
  - [`toolbox/rust.sh`](./toolbox/rust.sh): install Rust, and compile system tools
  - [`toolbox/stow.sh`](./toolbox/stow.sh): stow home directory configuration
  - [`toolbox/zellij.sh](./toolbox/zellij.sh): compile Zellij plugins
- Various notes, reminders and archived stuff are in [`notes/`](./notes)

> [!WARNING]
> This project makes no promises regarding backwards-compatibility. There are no
> stable releases. Things will break simply because I thought I would try
> something different.
