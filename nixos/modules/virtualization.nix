{ pkgs, ... }: {
  virtualisation.docker.enable = false;
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.defaultNetwork.dnsname.enable = true;
  virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
}
