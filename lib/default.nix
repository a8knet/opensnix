{
  lib,
  pkgs ? null,
  pkgsUtils ? import ./pkgs-utils.nix { inherit pkgs; },
}:
let
  utils = import ./utils.nix;
  types = import ./types.nix { inherit lib utils; };
  rules = import ./rules.nix {
    inherit
      lib
      pkgsUtils
      types
      utils
      ;
  };
in
rules // { inherit types utils; }
