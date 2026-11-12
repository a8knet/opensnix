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

  overridden = lib.filterAttrs (
    k: v: builtins.hasAttr k rendered && rendered.${k} != v
  ) config.services.opensnitch.rules;
in
{
  options.opensnix = {
    enable = lib.mkEnableOption "opensnix declarative OpenSnitch rules";

    defaultAction = lib.mkOption {
      type = lib.types.enum [
        "allow"
        "deny"
        "reject"
      ];
      default = "allow";
      example = "deny";
      description = ''
        Action applied to rules that do not specify an explicit
        `allow`, `deny` or `reject` subkey.
      '';
    };

    defaultPackageScope = lib.mkOption {
      type = opensnixLib.types.packageScope;
      default = "exact";
      example = "wildcard";
      description = ''
        Default package resolution scope. Can be overridden per-rule with
        `package.scope`.

        - `exact`: Resolve to a specific executable path
        - `wildcard`: Match any executable within the package's store
          directory, taken from its `bin` output; a multi-output package keeps
          executables in a directory suffixed with the output name (e.g.
          `curl-8.23.0-bin`). For a package whose directory name ends in
          `-wrapped` (e.g. `libreoffice-25.8.5.2-wrapped`), the suffix is
          stripped first and the unwrapped package's directory is matched,
          because the real binaries live there.
      '';
    };

    timestamp = lib.mkOption {
      type = opensnixLib.types.timestamp;
      default = opensnixLib.utils.flakeDateToRfc3339 self.lastModifiedDate;
      defaultText = lib.literalExpression ''
        opensnixLib.utils.flakeDateToRfc3339 self.lastModifiedDate
      '';
      example = "2026-10-02T18:31:07Z";
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
      type = lib.types.attrsOf opensnixLib.groupedRuleType;
      default = { };
      description = ''
        OpenSnitch rules. Each attribute name is the rule identifier; its
        value is either a bare fragment, an attrset with an `allow` subkey,
        or an attrset with a `deny` or `reject` subkey wrapping the fragment.
        A fragment carries one or more condition keys (see
        `opensnixLib.groupedRuleType` for the full typed schema).

        An entry that additionally sets `rules` to an attrset of child rules
        becomes a group: the group's condition fields, `allow`/`deny`/`reject`
        wrapper, and `precedence` are inherited by every child (child values
        win), and the generated rules are named `<group>-<child>`. Groups
        avoid repeating shared conditions such as `userName` across many
        rules. Children may nest further groups (unlimited depth).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    warnings =
      lib.optionals (!config.services.opensnitch.enable) [
        ''
          opensnix.enable is true but services.opensnitch.enable is false: opensnix
          only populates services.opensnitch.rules, and the OpenSnitch module
          ignores that option unless its service is enabled.
        ''
      ]
      ++ lib.optionals (overridden != { }) [
        ''
          opensnix: services.opensnitch.rules overrides opensnix-generated rules
          (${lib.concatStringsSep ", " (lib.attrNames overridden)}); those rules are
          no longer managed by opensnix alone.
        ''
      ];

    services.opensnitch.rules = rendered;
  };
}
