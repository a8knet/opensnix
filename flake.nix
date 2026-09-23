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
        tests = import ./tests { inherit opensnixLib; };
      };

      nixosModules.default =
        { config, lib, ... }:
        import ./modules {
          inherit config lib;
          self = self;
        };

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          nix-unit =
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
        }
      );
    };
}
