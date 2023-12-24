# :book: Yet Another Dotfiles Repo

```bash
export DOTFILES="${HOME}/.dotfiles"
git clone "git@github.com:zanbaldwin/dotfiles.git" "${DOTFILES}"
```

- User configuration files are stored in [`stow/`](./stow)
- Environment setup scripts are stored in [`toolbox/`](./toolbox)
- Various notes, reminders and archived stuff are in [`notes/`](./notes)

Follow the installation steps in [`install-fedora.md`](install-fedora.md);
if not using Silverblue, don't use `toolbox` to run scripts.

If not using Fedora, then read through the toolbox scripts and figure this
shit out yourself. User configuration has been written to at least try to
work well on macOS, but there are no guarantees.
