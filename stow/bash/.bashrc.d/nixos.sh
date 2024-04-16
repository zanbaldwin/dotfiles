if [ -f "/etc/NIXOS" ]; then
    alias switch="nixos-rebuild switch --flake '/dotfiles/nixos#$(hostname)'"
fi
