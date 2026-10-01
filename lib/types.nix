{ lib }:
{
  packageScopeType = lib.types.enum [
    "exact"
    "wildcard"
  ];
}
