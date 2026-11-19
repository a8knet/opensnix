# Option stubs for evaluating modules/default.nix outside a full NixOS
# eval. Not imported by modules/default.nix itself.
{ lib, ... }:
{
  options = {
    warnings = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      default = [ ];
      description = "Stub of the NixOS top-level warnings option.";
    };
    services.opensnitch = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        internal = true;
        description = "Stub of the real OpenSnitch module's enable option.";
      };
      rules = lib.mkOption {
        type = lib.types.submodule { freeformType = lib.types.json; };
        default = { };
        internal = true;
        description = "Stub of the real OpenSnitch module's rules option.";
      };
    };
  };
}
