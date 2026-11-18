{ lib, utils }:
let
  # POSIX shell-safe environment variable name.
  envNameClass = "[A-Za-z_][A-Za-z0-9_]*";
in
rec {
  packageScope = lib.types.enum [
    "exact"
    "wildcard"
  ];

  timestamp = (lib.types.addCheck lib.types.str utils.isRfc3339UTC) // {
    description = "RFC3339 UTC timestamp string";
  };

  # Protocol strings the OpenSnitch daemon can produce: its conman
  # parseDirection() sets "tcp", "udp", "udplite" and "sctp" (each suffixed
  # with "6" on IPv6), plus "icmp" and "icmp6". The daemon compares the
  # protocol case-insensitively, so accept any casing.
  protocol =
    let
      allowed = [
        "tcp"
        "tcp6"
        "udp"
        "udp6"
        "udplite"
        "udplite6"
        "sctp"
        "sctp6"
        "icmp"
        "icmp6"
      ];
    in
    (lib.types.addCheck lib.types.str (v: builtins.elem (lib.toLower v) allowed))
    // {
      description = "protocol, one of: ${lib.concatStringsSep ", " allowed}";
      descriptionClass = "noun";
    };

  # Element of a newline- or whitespace-delimited OpenSnitch list file
  # ('domains.list', 'ips.list', 'nets.list').
  listEntryStr = (lib.types.addCheck lib.types.str (v: builtins.match "[^[:space:]]+" v != null)) // {
    description = "non-empty string without whitespace";
    descriptionClass = "noun";
  };

  # String type that rejects empty patterns, embedded newlines, and leading '^'
  # or trailing '$' anchors, since regexp conditions wrap the pattern in
  # '^(?:<pattern>)$'. The group is essential: RE2 binds alternation looser than
  # anchors, so bare ^80|443$ parses as (^80)|(443$) and would match 8080 or
  # 1443; ^(?:80|443)$ matches only 80 or 443.
  regexpStr =
    (lib.types.addCheck lib.types.str (
      v: v != "" && !(lib.hasPrefix "^" v || lib.hasSuffix "$" v || lib.hasInfix "\n" v)
    ))
    // {
      description = "non-empty single-line string without leading '^' or trailing '$'";
      descriptionClass = "noun";
    };

  regexpSubmodule =
    innerType:
    (lib.types.submodule {
      _file = ./types.nix;
      options = {
        regexp = lib.mkOption {
          type = innerType;
          description = ".regexp value must be a string";
        };
      };
    })
    // {
      description = "{ regexp = ${innerType.description}; }";
      descriptionClass = "noun";
      getSubOptions = _: { };
    };

  # One environment variable condition: either the literal value to compare
  # against ('simple') or '{ regexp = "..."; }' ('regexp').
  envValue = lib.types.either lib.types.str (regexpSubmodule regexpStr);

  # Conditions keyed by environment variable name, each rendered to its own
  # 'process.env.<NAME>' operand.
  envVars =
    (lib.types.addCheck (lib.types.attrsOf envValue) (
      v: lib.all (n: builtins.match envNameClass n != null) (lib.attrNames v)
    ))
    // {
      description = "attribute set of environment variable conditions";
      descriptionClass = "noun";
    };
}
