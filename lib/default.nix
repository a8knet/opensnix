{ lib, pkgs }:
let
  utils = import ./utils.nix { inherit pkgs; };
in
import ./rules.nix { inherit lib utils; }
