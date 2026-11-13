# opensnix

[![CI](https://github.com/a8knet/opensnix/actions/workflows/ci.yml/badge.svg)](https://github.com/a8knet/opensnix/actions/workflows/ci.yml)

A more user-friendly interface for
[OpenSnitch](https://github.com/evilsocket/opensnitch) rules on NixOS.

## Documentation

Full documentation, user guides, and the generated configuration option
reference are published at:

**[https://a8knet.github.io/opensnix/](https://a8knet.github.io/opensnix/)**

## Quick Start

Add `opensnix` as a flake input and import its NixOS module:

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

Then enable both `services.opensnitch` and `opensnix` and declare rules:

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
      telemetry.deny.host.regexp = ".*[.]telemetry[.]example[.]com";
    };
  };
}
```

See the [online documentation](https://a8knet.github.io/opensnix/) for the
complete [User Guide](https://a8knet.github.io/opensnix/guide/rules.html) and
[Configuration Options](https://a8knet.github.io/opensnix/reference/options.html)
reference, or build the book locally with `nix build .#docs`.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for the full text.
