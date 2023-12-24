# :book: Yet Another Dotfiles Repo

```bash
export DOTFILES="${HOME}/.dotfiles"
git clone "git@github.com:zanbaldwin/dotfiles.git" "${DOTFILES}"
```

- Based on [Fedora Silverblue](https://silverblue.fedoraproject.org/), the
  custom operating system base is built using an OCI image definition. See the
  [README in the `oci/` directory](./oci) for build and rebasing instructions.
- Customised keymap firmware for a Corne keyboard can be found in
  [`qmk/`](./qmk) and the script to set that up can be found at
  [`toolbox/qmk.sh`](./toolbox/qmk.sh).
- Environment setup scripts are stored in [`toolbox/`](./toolbox)
- User configuration files are stored in [`stow/home/`](./stow/home) and can be
  installed via the [`stow.sh`](toolbox/stow.sh) script.
- Various notes, reminders and archived stuff are in [`notes/`](./notes)

> This project makes no promises regarding backwards-compatibility. There are no
> stable releases. Things will break simply because I thought I would try
> something different.

Follow the installation steps in [`install-fedora.md`](install-fedora.md);
if not using Silverblue, don't use `toolbox` to run scripts.

If not using Fedora, then read through the toolbox scripts and figure this
shit out yourself. User configuration has been written to at least try to
work well on macOS, but there are no guarantees.
