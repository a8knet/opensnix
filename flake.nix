{
  description = "A more user-friendly interface for OpenSnitch rules on NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      checks = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          nix-unit = pkgs.runCommand "opensnix-tests"
            {
              nativeBuildInputs = [ pkgs.nix-unit ];
            }
            ''
              export HOME="$(realpath .)"
              nix-unit --eval-store "$HOME" ${./tests}
              touch $out
            '';
        });
    };
}
