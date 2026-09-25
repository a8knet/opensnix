{ opensnixLib, lib }:
let
  inherit (opensnixLib) mkRules;

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
  # real nix-unit test: wrap the input with mkRules, and merge each expected
  # rule body with the invariant `base` fields.
  transform = t: {
    expr = mkRules {
      defaultAction = t.defaultAction or "allow";
      timestamp = ts;
      rules = t.expr;
    };
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
