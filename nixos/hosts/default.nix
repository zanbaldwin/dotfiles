{ nixpkgs, lib, inputs, username, home-manager, ... }: {
    # KVM Virtual Machine
    qemu = let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in lib.nixosSystem {
        inherit system;
        specialArgs = { inherit system pkgs username inputs; };
        modules = [
            ./qemu/hardware.nix
            ./qemu/bootloader.nix
            ../configuration.nix
        ];
    };

    # Desktop
    tuffed = let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in lib.nixosSystem {
        inherit system;
        specialArgs = { inherit system pkgs username inputs; };
        modules = [
            ./tuffed/hardware.nix
            ./tuffed/bootloader.nix
            ../configuration.nix
            # home-manager.nixosModules.home-manager {
            #     home-manager.useGlobalPkgs = true;
            #     home-manager.useUserPackages = true;
            #     home-manager.extraSpecialArgs = { inherit username; };
            #     home-manager.users.${username} = {
            #         imports = [ (import ../home.nix) ++ (import ./tuffed/home.nix) ]
            #     };
            # }
        ];
    };
}
