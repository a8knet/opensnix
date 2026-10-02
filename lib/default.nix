{ lib, pkgs }:
let
  pkgsUtils = import ./pkgs-utils.nix { inherit pkgs; };
  types = import ./types.nix { inherit lib; };
  rules = import ./rules.nix {
    inherit lib pkgsUtils types;
  };
in
rules // types
