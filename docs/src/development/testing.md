# Testing, Linting & Formatting

## Running Checks

Unit tests use [nix-unit](https://github.com/nix-community/nix-unit) and live
in `tests/unit/`. In addition, `checks.shell-realpath`
(`tests/shell/realpath.nix`) tests the `lib/pkgs-utils.nix` builder script
against real derivations instead of the unit-test mock, and `checks.docs`
verifies that the `mdBook` documentation site and option reference build
cleanly.

```sh
nix flake check
```

## How the Tests Are Organized

Three test categories live under `tests/`:

- **`tests/unit/`**: Mocked pure-evaluation suites run by `nix-unit`.
- **`tests/shell/`**: Contracts for shell builder scripts, exposed as
  `checks.x86_64-linux.shell-<filename>`, taking `{ pkgs, utils }` and
  returning a derivation.
- **`tests/vm/`**: NixOS VM integration tests against the real `opensnitchd`
  daemon.

Unit tests are pure-data suites under `tests/unit/` - one `*.nix` file per
group of related cases, each entry a `{ expr, expected }` pair. `expr` is the
raw `opensnix` rules; `expected` is the OpenSnitch rule body minus the
invariant `base` fields. `tests/unit/default.nix` auto-discovers every `*.nix`
under `tests/unit/` (except itself), wraps `expr` with `mkRules`, merges
`expected` with `base`, and namespaces each test as `test-<suite>-<key>`. A
test may also set `defaultAction` (default `"allow"`) or `expectedWarnings`.

To add a unit test, drop a `{ expr, expected }` entry into an existing suite or
create a new `*.nix` file under `tests/unit/`.

## VM Smoke Test

`tests/vm/` holds NixOS VM tests that boot a real OpenSnitch daemon and assert
that every rule `opensnix` renders is deployed and loaded properly. Because VM
tests build a disk image and require KVM, they are exposed under `vmTests`
rather than `checks`:

```sh
nix build .#vmTests.x86_64-linux.smoke -L
```

## Formatting and Linting

Formatting uses [nixfmt](https://github.com/NixOS/nixfmt) (via `nixfmt-tree`),
and linting uses [statix](https://github.com/oppiliappan/statix) plus
[deadnix](https://github.com/astro/deadnix):

```sh
nix fmt            # format every .nix file in the tree
nix flake check    # runs unit tests, docs, linter, formatter, and shell checks
```

To build only the documentation site or run only the linter locally:

```sh
nix build .#docs
nix build .#checks.x86_64-linux.lint
```
