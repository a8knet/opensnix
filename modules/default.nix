{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  opensnixLib = self.lib.default { inherit lib pkgs; };
  cfg = config.opensnix;

  rendered = opensnixLib.mkRules {
    inherit (cfg)
      defaultAction
      defaultPackageScope
      rules
      timestamp
      ;
  };
in
{
  options.opensnix = {
    enable = lib.mkEnableOption "opensnix declarative OpenSnitch rules";

    defaultAction = lib.mkOption {
      type = lib.types.enum [
        "allow"
        "deny"
      ];
      default = "allow";
      description = ''
        Action applied to rules that do not specify an explicit
        `allow` or `deny` subkey.
      '';
    };

    defaultPackageScope = lib.mkOption {
      type = opensnixLib.packageScopeType;
      default = "exact";
      description = ''
        Default package resolution scope. Can be overridden per-rule with
        `package.scope`.

        - `exact`: Resolve to a specific executable path
        - `wildcard`: Match any executable within the package directory
      '';
    };

    timestamp = lib.mkOption {
      type = opensnixLib.timestampType;
      default = opensnixLib.utils.flakeDateToRfc3339 self.lastModifiedDate;
      description = ''
        Timestamp used for the `created`/`updated` fields of every rule.
        Must be an RFC3339 UTC date-time: exactly `YYYY-MM-DDTHH:MM:SSZ`
        (e.g. `2026-10-02T18:31:07Z`), with no fractional seconds and no
        numeric timezone offset.

        Defaults to the flake's `lastModifiedDate` converted from its
        `YYYYMMDDHHMMSS` form to an RFC3339 UTC timestamp.
      '';
    };

    rules = lib.mkOption {
      type = lib.types.attrsOf opensnixLib.ruleType;
      default = { };
      description = ''
        OpenSnitch rules. Each attribute name is the rule identifier; its
        value is either a bare fragment, an attrset with an `allow` subkey,
        or an attrset with a `deny` subkey wrapping the fragment. A fragment
        carries one or more condition keys (see `opensnixLib.ruleType` for the
        full typed schema).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.opensnitch.rules = rendered;
  };
}
