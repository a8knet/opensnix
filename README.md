# opensnix

[![CI](https://github.com/a8knet/opensnix/actions/workflows/ci.yml/badge.svg)](https://github.com/a8knet/opensnix/actions/workflows/ci.yml)

A more user-friendly interface for
[OpenSnitch](https://github.com/evilsocket/opensnitch) rules on NixOS.

## Usage

Add opensnix as a flake input and import its NixOS module:

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

Then enable opensnix and declare rules in any module or `configuration.nix`:

```nix
{ pkgs, ... }:
{
  services.opensnitch.enable = true;

  opensnix = {
    enable = true;
    rules = {
      # ... rules go here, see Examples below
    };
  };
}
```

opensnix only populates `services.opensnitch.rules`, and the OpenSnitch module
reads that option only while `services.opensnitch.enable` is true, so the
service has to be enabled as well.

The option names accepted under `opensnix`, and the condition keys accepted by
each rule, are declared in
[`modules/default.nix`](modules/default.nix) and
[`lib/rules.nix`](lib/rules.nix).

### Examples

Each example is an entry of `opensnix.rules`; the attribute name is the rule
identifier, and opensnix prefixes generated rule names with `opensnix-`.

#### Network

```nix
opensnix.rules.lan.network = "10.0.0.0/8";
```

An entry with no explicit `allow` or `deny` subkey gets
`opensnix.defaultAction`, which is `"allow"` unless you set it otherwise.

#### Package, with wildcard scope

```nix
opensnix.rules.firefox.package = {
  value = pkgs.firefox;
  scope = "wildcard";
};
```

`package` turns a Nix package into a process condition. The default scope
resolves to the package's main executable; `scope = "wildcard"` matches every
binary inside the package instead.

#### Group with inherited children

```nix
opensnix.rules.systemd-resolved = {
  userName = "systemd-resolve";
  rules = {
    dns = {
      network = "LAN";
      port = 53;
    };
    dnssec = {
      domains = [ "example.org" ];
      port = 853;
    };
  };
};
```

Setting `rules` makes the entry a group: its conditions, its `allow`/`deny`
wrapper and its `precedence` are inherited by every child, with the child
winning on conflict. The two rules above are generated as
`opensnix-systemd-resolved-dns` and `opensnix-systemd-resolved-dnssec`, and both
carry `userName = "systemd-resolve"`. Groups nest to any depth.

#### Deny, with a regexp host

```nix
opensnix.rules.telemetry.deny.host.regexp = ".*[.]telemetry[.]example[.]com";
```

Keys that match a pattern rather than a single exact value — `host`, the `ip`
and `port` variants, `processPath`, `processCommand`, and the `domains` and
`hosts` lists — accept a `{ regexp = …; }` subkey in place of a plain value. The
`^` and `$` anchors are added for you, so writing them yourself is an error.

## Running tests

Unit tests use [nix-unit](https://github.com/nix-community/nix-unit) and live
in the `tests/` directory.

```sh
nix flake check
```

### How the tests are organized

Tests are pure-data suites under `tests/` — one `*.nix` file per group of
related cases, each entry a `{ expr, expected }` pair. `expr` is the raw opensnix
rules; `expected` is the OpenSnitch rule body minus the invariant `base` fields.
`tests/default.nix` auto-discovers every `*.nix` under `tests/` (except itself),
wraps `expr` with `mkRules`, merges `expected` with `base`, and namespaces each
test as `test-<suite>-<key>`. A test may set `defaultAction` (default `"allow"`)
for rules that don't specify `allow`/`deny`.

To add a test, drop a `{ expr, expected }` entry into a suite, or add a new
suite file — both are picked up automatically.

## Formatting and linting

Formatting uses [nixfmt](https://github.com/NixOS/nixfmt) (the official Nix
formatter, via `nixfmt-tree`), and linting uses
[statix](https://github.com/oppiliappan/statix) plus
[deadnix](https://github.com/astro/deadnix).

```sh
nix fmt            # format every .nix file in the tree
nix flake check    # runs unit tests and the linter (statix + deadnix)
```

Linting is enforced by `nix flake check`. To run only the linter locally:

```sh
nix build .#checks.x86_64-linux.lint
```

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for the full text.
