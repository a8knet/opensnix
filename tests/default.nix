{ opensnixLib, lib }:
let
  # Shared timestamp and the invariant fields every emitted rule carries.
  ts = "2026-09-22T00:00:00.000000000+00:00";
  base = {
    created = ts;
    updated = ts;
    enabled = true;
    duration = "always";
  };

  # Discover suite files automatically: every .nix file directly under this
  # directory (except default.nix itself) is a suite of pure-data tests.
  suiteNames = lib.attrNames (
    lib.filterAttrs (n: t: t == "regular" && n != "default.nix" && lib.hasSuffix ".nix" n) (
      builtins.readDir ./.
    )
  );

  # Turn a raw test (opensnix rules + literal opensnitch rule bodies) into a
  # real nix-unit test by running it through the actual NixOS module via
  # evalModules. The stub services.opensnitch.rules option mirrors what the
  # real OpenSnitch module provides; the rendered rules are plain data and
  # safe to compare outside the module evaluation.
  transform =
    t:
    let
      eval = lib.evalModules {
        modules = [
          (
            { lib, ... }:
            {
              imports = [ ../modules ];
              options.services.opensnitch.rules = lib.mkOption {
                type = lib.types.attrs;
                description = "Stub of the real OpenSnitch module's rules option.";
              };
              config = {
                _module.args.self = {
                  lib = opensnixLib;
                  lastModifiedDate = ts;
                };
                opensnix = {
                  enable = lib.mkForce true;
                  defaultAction = t.defaultAction or "allow";
                  rules = t.expr;
                  timestamp = ts;
                };
              };
            }
          )
        ];
      };
      rules = eval.config.services.opensnitch.rules;
    in
    if t ? expectedError then
      {
        inherit (t) expectedError;
        expr = rules;
      }
    else
      {
        expr = rules;
        expected = lib.mapAttrs (_: r: base // r) t.expected;
      };

  # Import a suite file, namespace each test as test-<basename>-<key>, transform it.
  load =
    name:
    let
      suite = import (./. + "/${name}");
      baseName = lib.removeSuffix ".nix" name;
    in
    lib.mapAttrs' (k: v: lib.nameValuePair "test-${baseName}-${k}" (transform v)) suite;
in
lib.foldl' (acc: n: acc // load n) { } suiteNames
