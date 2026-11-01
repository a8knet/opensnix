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
binary inside the package instead. Resolving an executable runs `realpath` in a
build phase (import-from-derivation): evaluating such a rule builds the package
at eval time. `path` and `scope = "wildcard"` avoid that; they only use the
store path.

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

#### Condition aliases

Some condition keys are aliases of others and map to the same OpenSnitch
operand:

| alias        | canonical    | operand            |
| ------------ | ------------ | ------------------ |
| `dstPort`    | `port`       | `dest.port`        |
| `dstPorts`   | `ports`      | `dest.port`        |
| `dstIp`      | `ip`         | `dest.ip`          |
| `dstNetwork` | `network`    | `dest.network`     |
| `user`       | `userName`   | `user.name`        |
| `ifaceOut`   | `iface`      | `iface.out`        |
| `hosts`      | `domains`    | `lists.domains`    |

A rule may set at most one condition per operand, so combining an alias with
its canonical key (`domains` together with `hosts`) or two shapes of the same
operand (`port = 53` together with `ports = [ 53 853 ]`) is an evaluation
error. OpenSnitch ANDs an operator's children, and two conditions on one
operand are always redundant or impossible to satisfy together. Use the
plural list fields (`ports`, `ips`, `nets`, `domains`) for OR over one field
and the array fields (`users`, `userNames`, `userIds`) to expand one rule per
value. Note that singular `host` (exact `dest.host`) is its own condition,
distinct from the `hosts` alias.

## Running tests

Unit tests use [nix-unit](https://github.com/nix-community/nix-unit) and live
in the `tests/unit/` directory. `checks.shell-realpath`
(`tests/shell/realpath.nix`) additionally tests the `lib/pkgs-utils.nix` builder
script directly instead of the unit-test mock.

```sh
nix flake check
```

### How the tests are organized

Three categories live under `tests/`: `unit/` — mocked pure-evaluation suites;
`shell/` — contracts for shell builder scripts, run as flake checks; `vm/` —
integration against the real opensnitchd daemon. Every `*.nix` file in
`tests/shell/` becomes a check `shell-<filename>`, taking `{ pkgs, utils }` and
returning a derivation.

Tests are pure-data suites under `tests/unit/` — one `*.nix` file per group of
related cases, each entry a `{ expr, expected }` pair. `expr` is the raw opensnix
rules; `expected` is the OpenSnitch rule body minus the invariant `base` fields.
`tests/unit/default.nix` auto-discovers every `*.nix` under `tests/unit/` (except
itself), wraps `expr` with `mkRules`, merges `expected` with `base`, and namespaces
each test as `test-<suite>-<key>`. A test may set `defaultAction` (default
`"allow"`) for rules that don't specify `allow`/`deny`.

To add a test, drop a `{ expr, expected }` entry into a suite, or add a new
suite file — both are picked up automatically.

### VM smoke test

`tests/vm/` holds NixOS VM tests that boot a real OpenSnitch daemon and
assert that every rule opensnix renders is deployed and loaded correctly.
These are deliberately not part of `nix flake check` (they build a disk
image and need KVM); CI runs them in a separate job. To run one locally:

```sh
nix build .#vmTests.x86_64-linux.smoke -L
```

## Formatting and linting

Formatting uses [nixfmt](https://github.com/NixOS/nixfmt) (the official Nix
formatter, via `nixfmt-tree`), and linting uses
[statix](https://github.com/oppiliappan/statix) plus
[deadnix](https://github.com/astro/deadnix).

```sh
nix fmt            # format every .nix file in the tree
nix flake check    # runs unit tests, linter, formatter, and shell checks
```

Linting is enforced by `nix flake check`. To run only the linter locally:

```sh
nix build .#checks.x86_64-linux.lint
```

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for the full text.
