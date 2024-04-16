# NixOS Flake Configuration

Hosts defined in the [`hosts` NixOS module](./hosts/default.nix).

```shell
export HOST="<choose-host>"
```

## Installation

```shell
sudo nixos-install --flake "https://github.com/zanbaldwin/dotfiles#${HOST}"
```

## Upgrading

```shell
git clone "https://github.com/zanbaldwin/dotfiles" "/dotfiles"
sudo nixos-rebuild switch --flake "/dotfiles#${HOST}"
```
