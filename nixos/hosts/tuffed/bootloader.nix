{ config, pkgs, ... }: {
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
    # If you haven't figured out you want to roll-back within 16 generations of
    # config switching, then tough luck. Everything should be in Git anyway.
    configurationLimit = 16;
    consoleMode = "keep";
  };
  boot.loader.efi.canTouchEfiVariables = true;
}
