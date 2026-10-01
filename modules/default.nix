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
      type = lib.types.str;
      default = self.lastModifiedDate;
      description = ''
        Timestamp used for the `created`/`updated` fields of every rule.
        Defaults to the flake's `self.lastModifiedDate`.
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
