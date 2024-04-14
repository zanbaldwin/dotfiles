# NixOS Flake Configuration

```shell
SYSTEM_HOSTNAME="qemu"
DEFAULT_DOTFILES_DIR="/dotfiles"
git clone "https://github.com/zanbaldwin/dotfiles.git" "${DEFAULT_DOTFILES_DIR}"
sudo nixos-rebuild switch --flake "${DEFAULT_DOTFILES_DIR}/nixos#${SYSTEM_HOSTNAME}"
```
