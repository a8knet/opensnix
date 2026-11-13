# opensnix

## Repository Layout

- `flake.nix` - Flake outputs (`lib`, `nixosModules`, `packages`, `formatter`,
  `checks`, `vmTests`).
- `modules/` - NixOS module entry point and top-level options.
- `lib/` - Rule schema, package resolution, and OpenSnitch rule rendering.
- `docs/` - Documentation website (`mdBook`) and generated option reference.
- `tests/unit/` - Pure-evaluation `nix-unit` test suites.
- `tests/shell/` - Shell builder contract checks.
- `tests/vm/` - NixOS VM integration tests against `opensnitchd`.

## Commands

```sh
# Run all flake checks (unit tests, docs, linter, formatter, shell checks)
nix flake check

# Format all .nix files
nix fmt

# Run linter only
nix build .#checks.x86_64-linux.lint

# Build the documentation website
nix build .#docs

# Run the NixOS VM smoke test (requires KVM)
nix build .#vmTests.x86_64-linux.smoke -L
```

## Conventions

- **Plain ASCII**: Write Nix code, comments, Markdown, and commit messages in
  plain ASCII (`...`, `-`, `'`, `"` instead of Unicode ellipses, em dashes, or
  curly quotes).
- **Terse errors and comments**: Keep `builtins.throw` messages and code
  comments short and factual (1-2 lines max), matching sibling style.
- **Option metadata**: Every visible option under `opensnix` must have a
  non-empty `description` and an in-tree `_file` declaration (enforced by
  `docs/default.nix`).
- **Testing**: See
  [`docs/src/development/testing.md`](docs/src/development/testing.md) for how
  test suites are organized.
