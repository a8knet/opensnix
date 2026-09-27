{
  config,
  lib,
  self,
  pkgs,
  ...
}:
let
  opensnixLib = self.lib;
  cfg = config.opensnix;

  rendered = opensnixLib.mkRules {
    inherit (cfg) defaultAction rules timestamp;
    inherit (pkgs) writeTextDir;
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
