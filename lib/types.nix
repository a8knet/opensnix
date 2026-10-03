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
}
