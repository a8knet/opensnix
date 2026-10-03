{ lib }:
let
  utils = import ./utils.nix;
in
{
  packageScopeType = lib.types.enum [
    "exact"
    "wildcard"
  ];

  timestampType = (lib.types.addCheck lib.types.str utils.isRfc3339UTC) // {
    description = "RFC3339 UTC timestamp string";
  };
}
