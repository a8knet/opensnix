# opensnix

A more user-friendly interface for
[OpenSnitch](https://github.com/evilsocket/opensnitch) rules on NixOS.

## Running tests

Unit tests use [nix-unit](https://github.com/nix-community/nix-unit) and live
in the `tests/` directory.

```sh
nix flake check
```

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
