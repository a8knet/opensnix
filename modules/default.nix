{
  config,
  lib,
  self,
}:
let
  opensnixLib = self.lib;
  cfg = config.opensnix;

  rendered = opensnixLib.mkRules {
    inherit (cfg) defaultAction rules timestamp;
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
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        OpenSnitch rules. Each attribute name is the rule identifier; its
        value is either a rule fragment or an attrset with an `allow` or
        `deny` subkey wrapping the fragment.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.opensnitch.rules = rendered;
  };
}
