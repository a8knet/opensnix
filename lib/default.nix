{ lib, pkgs }:
let
  utils = import ./utils.nix { inherit pkgs; };
  types = import ./types.nix { inherit lib; };
  rules = import ./rules.nix {
    inherit lib utils types;
  };
in
rules // types
