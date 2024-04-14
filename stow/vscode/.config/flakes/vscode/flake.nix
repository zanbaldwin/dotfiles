{
  description = "VSCode Dependencies";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      dependencies = with pkgs; [
        nil
        nixpkgs-fmt
      ];
    in
    {
      inherit system;
      packages.${system}.default = pkgs.buildEnv {
        name = "vscode-depdendencies";
        paths = dependencies;
      };
      devShells.default = pkgs.mkShell {
        buildInputs = dependencies;
      };
    };
}
