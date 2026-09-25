# opensnix

A more user-friendly interface for
[OpenSnitch](https://github.com/evilsocket/opensnitch) rules on NixOS.

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
