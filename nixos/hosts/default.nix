{ nixpkgs, lib, inputs, username, ... }: {
    # KVM Virtual Machine
    qemu = let
      hostname = "qemu";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in lib.nixosSystem {
        inherit system;
        specialArgs = { inherit system pkgs username inputs hostname; };
        modules = [
            ./qemu/hardware.nix
            ./qemu/bootloader.nix
            ../configuration.nix
        ];
    };

    # Desktop
    tuffed = let
      hostname = "tuffed";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in lib.nixosSystem {
        inherit system;
        specialArgs = { inherit system pkgs username inputs hostname; };
        modules = [
            ./tuffed/hardware.nix
            ./tuffed/bootloader.nix
            ../configuration.nix
        ];
    };
}
