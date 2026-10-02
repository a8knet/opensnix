{ lib }:
let
  # RFC3339 date-time restricted to UTC: exactly
  # YYYY-MM-DDTHH:MM:SSZ (no fractional seconds, no numeric offset).
  rfc3339UTCRegexp = "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z";

  # Whether the given string is a valid RFC3339 UTC date-time.
  isRfc3339UTC = s: builtins.isString s && builtins.match rfc3339UTCRegexp s != null;
in
{
  packageScopeType = lib.types.enum [
    "exact"
    "wildcard"
  ];

  inherit isRfc3339UTC;

  timestampType = (lib.types.addCheck lib.types.str isRfc3339UTC) // {
    description = "RFC3339 UTC timestamp string";
  };

  # Convert a flake `lastModifiedDate` (YYYYMMDDHHMMSS) into an RFC3339 UTC
  # timestamp. Any other value is passed through unchanged so that
  # `timestampType` reports it as invalid.
  flakeDateToRfc3339 =
    d:
    if builtins.match "[0-9]{14}" d != null then
      let
        s = i: l: builtins.substring i l d;
      in
      "${s 0 4}-${s 4 2}-${s 6 2}T${s 8 2}:${s 10 2}:${s 12 2}Z"
    else
      d;
}
