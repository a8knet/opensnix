{
  rules,
  lib,
  types,
}:
let
  mockWriteTextDir = name: content: { inherit name content; };

  mockUtils = {
    writeTextDir = mockWriteTextDir;
    realpath = x: x;
  };

  opensnixLib =
    (rules {
      inherit lib types;
      utils = mockUtils;
    })
    // types;

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
              options.services.opensnitch.rules = lib.mkOption {
                type = lib.types.attrs;
                description = "Stub of the real OpenSnitch module's rules option.";
              };
              config = {
                _module.args.self = {
                  lib = {
                    default = _: opensnixLib;
                  };
                  lastModifiedDate = t.lastModifiedDate or ts;
                };
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

  load =
    name:
    let
      suite = import (./. + "/${name}");
      baseName = lib.removeSuffix ".nix" name;
    in
    lib.mapAttrs' (k: v: lib.nameValuePair "test-${baseName}-${k}" (transform v)) suite;
in
lib.foldl' (acc: n: acc // load n) { } suiteNames
