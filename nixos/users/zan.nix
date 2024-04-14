{ config, pkgs, ... }: let
  username = "zan";
in {
  # Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    createHome = true;
    description = "Zan Baldwin";
    initialPassword = "password";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirt"
    ];
    shell = pkgs.bashInteractive;
    packages = with pkgs; [
      alacritty
      atuin
      bat
      bitwarden
      btop
      delta
      difftastic
      docker-compose
      duf
      eza
      firefox
      glow
      gum
      hexyl
      jq
      mkcert
      onefetch
      ripgrep
      spotify
      spotifyd
      spotify-tui
      starship
      zellij
    ];
  };
  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = username;
  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
