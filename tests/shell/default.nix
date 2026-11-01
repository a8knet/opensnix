{ pkgs }:
let
  inherit (pkgs) lib;
  utils = import ../../lib/pkgs-utils.nix { inherit pkgs; };

  fileNames = lib.attrNames (
    lib.filterAttrs (n: t: t == "regular" && n != "default.nix" && lib.hasSuffix ".nix" n) (
      builtins.readDir ./.
    )
  );

  checks = lib.genAttrs (builtins.map (lib.removeSuffix ".nix") fileNames) (
    name: import (./. + "/${name}.nix") { inherit pkgs utils; }
  );
in
# Every *.nix file here is one flake check, emitted as shell-<filename>.
# Each file takes { pkgs, utils } and returns a derivation; build success passes.
lib.mapAttrs' (n: v: lib.nameValuePair "shell-${n}" v) checks
