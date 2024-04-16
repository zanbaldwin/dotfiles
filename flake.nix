{
    description = "Flakey NixOS";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    };

    outputs = inputs @ { self, nixpkgs }: let
        username = "zan";
        lib = nixpkgs.lib;
    in {
        nixosConfigurations = (import ./nixos/hosts {
            inherit nixpkgs lib inputs username;
        });
    };
}
