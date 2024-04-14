{
  description = "NVim Dependencies";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      dependencies = with pkgs; [
        alejandra
        deadnix
        gcc
        go
        luarocks
        neovim
        nil
        nixfmt
        php83
        statix
      ];
    in
    {
      inherit system;
      packages.${system}.default = pkgs.buildEnv {
        name = "nvim-depdendencies";
        paths = dependencies;
      };
      devShells.default = pkgs.mkShell {
        buildInputs = dependencies;
      };
    };
}
