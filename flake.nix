{
  description = "A more user-friendly interface for OpenSnitch rules on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      opensnixLib = import ./lib { inherit (nixpkgs) lib; };

      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = nixpkgs.legacyPackages;
    in
    {
      lib = opensnixLib // {
        tests = import ./tests {
          inherit opensnixLib;
          inherit (nixpkgs) lib;
        };
      };

      nixosModules.default =
        { config, lib, ... }:
        import ./modules {
          inherit config lib self;
        };

      formatter = forAllSystems (system: pkgsFor.${system}.nixfmt-tree);

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          test =
            pkgs.runCommand "opensnix-tests"
              {
                nativeBuildInputs = [ pkgs.nix-unit ];
              }
              ''
                export HOME="$(realpath .)"
                nix-unit --eval-store "$HOME" \
                  --extra-experimental-features flakes \
                  --override-input nixpkgs ${nixpkgs} \
                  --flake ${self}#lib.tests
                touch $out
              '';

          lint =
            pkgs.runCommand "opensnix-lint"
              {
                nativeBuildInputs = [
                  pkgs.statix
                  pkgs.deadnix
                ];
              }
              ''
                statix check ${./.}
                deadnix --fail ${./.}
                touch $out
              '';
        }
      );
    };
}
