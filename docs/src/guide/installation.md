# Installation & Usage

Add `opensnix` as a flake input and import `opensnix.nixosModules.default` into
your NixOS configuration:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opensnix.url = "github:a8knet/opensnix";
    opensnix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, opensnix, ... }:
    {
      nixosConfigurations.hoster = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          opensnix.nixosModules.default
          ./configuration.nix
        ];
      };
    };
}
```

Then enable both `services.opensnitch` and `opensnix`, and declare your rules
in any NixOS module or `configuration.nix`:

```nix
{ pkgs, ... }:
{
  services.opensnitch.enable = true;

  opensnix = {
    enable = true;
    rules = {
      lan.network = "10.0.0.0/8";
      firefox.package = {
        value = pkgs.firefox;
        scope = "wildcard";
      };
    };
  };
}
```

`opensnix` only populates `services.opensnitch.rules`, and the upstream
OpenSnitch NixOS module reads that option only while
`services.opensnitch.enable` is `true`, so both options must be enabled.
Enabling `opensnix` while `services.opensnitch.enable` is `false` emits an
evaluation warning.
