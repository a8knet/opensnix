{
  rules,
  lib,
}:
let
  mockWriteTextDir = name: content: { inherit name content; };

  mockPkgsUtils = {
    writeTextDir = mockWriteTextDir;
    realpath = x: x;
  };

  opensnixLib =
    (rules {
      inherit lib;
      pkgsUtils = mockPkgsUtils;
    })
    // {
      types = import ../lib/types.nix { inherit lib; };
      utils = import ../lib/utils.nix;
    };

  ts = "2026-09-22T00:00:00Z";

  suiteNames = lib.attrNames (
    lib.filterAttrs (n: t: t == "regular" && n != "default.nix" && lib.hasSuffix ".nix" n) (
      builtins.readDir ./.
    )
  );

  transform =
    t:
    let
      useDefaultTimestamp = t.useDefaultTimestamp or false;
      expectedTs = t.expectedTs or (t.timestamp or ts);
      base = {
        created = expectedTs;
        updated = expectedTs;
        enabled = true;
        duration = "always";
      };
      eval = lib.evalModules {
        modules = [
          (
            { lib, ... }:
            {
              imports = [ ../modules ];
              options = {
                warnings = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  internal = true;
                  default = [ ];
                  description = "Stub of the NixOS top-level warnings option.";
                };
                services.opensnitch = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Stub of the real OpenSnitch module's enable option.";
                  };
                  rules = lib.mkOption {
                    type = lib.types.attrs;
                    description = "Stub of the real OpenSnitch module's rules option.";
                  };
                };
              };
              config = {
                _module.args.self = {
                  lib = {
                    default = _: opensnixLib;
                  };
                  lastModifiedDate = t.lastModifiedDate or ts;
                };
                services.opensnitch.enable = t.opensnitchServiceEnable or true;
                opensnix = {
                  enable = lib.mkForce true;
                  defaultAction = t.defaultAction or "allow";
                  rules = t.expr;
                }
                // lib.optionalAttrs (!useDefaultTimestamp) {
                  timestamp = t.timestamp or ts;
                };
              };
            }
          )
        ];
      };
      warnings = eval.config.warnings;
      warningCheck =
        if !(t ? expectedWarnings) then
          true
        else if t.expectedWarnings == [ ] then
          lib.assertMsg (warnings == [ ]) "unexpected warnings: ${lib.generators.toPretty { } warnings}"
        else
          lib.assertMsg (lib.all (w: lib.any (lib.strings.hasInfix w) warnings) t.expectedWarnings)
            "expected a warning matching one of ${lib.generators.toPretty { } t.expectedWarnings}, got ${
              lib.generators.toPretty { } warnings
            }";
      rules = lib.showWarnings warnings (
        if warningCheck then eval.config.services.opensnitch.rules else null
      );
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

  load =
    name:
    let
      suite = import (./. + "/${name}");
      baseName = lib.removeSuffix ".nix" name;
    in
    lib.mapAttrs' (k: v: lib.nameValuePair "test-${baseName}-${k}" (transform v)) suite;
in
lib.foldl' (acc: n: acc // load n) { } suiteNames
