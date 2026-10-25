{ lib }:
let
  utils = import ./utils.nix;
in
{
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
}
