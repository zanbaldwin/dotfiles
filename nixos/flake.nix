{
  description = "Flakey NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager }: let
    username = "zan";
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = (import ./hosts {
      inherit nixpkgs lib inputs username home-manager;
    });
  };
}
