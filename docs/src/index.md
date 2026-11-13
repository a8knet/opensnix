# opensnix

**opensnix** provides a concise, declarative NixOS interface for authoring
[OpenSnitch](https://github.com/evilsocket/opensnitch) application firewall
rules.

Instead of writing verbose OpenSnitch JSON operator trees by hand under
`services.opensnitch.rules`, `opensnix` lets you express rules in terms of Nix
packages, hostnames, ports, CIDR networks, domain lists, regular expressions,
and hierarchical rule groups with inheritance.

## Highlights

- **Concise rule syntax**: Write `opensnix.rules.lan.network = "10.0.0.0/8";`
  instead of nested `operator` records.
- **First-class Nix package resolution**: Match a package's main binary
  (`exact` scope) or every executable inside its store directory (`wildcard`
  scope), with support for wrapped binaries (`toWrapped`).
- **Hierarchical rule groups**: Share common conditions, actions, and
  precedence across nested child rules under `rules = { ... };`.
- **Built-in validation**: Detects conflicting condition aliases, duplicate
  operands, invalid regexp anchors, and collisions with hand-written
  `services.opensnitch.rules` entries at Nix evaluation time.

## Where to Start

- [Installation & Usage](guide/installation.md) - Add `opensnix` to your flake
  and enable the module.
- [Writing Rules](guide/rules.md) - Actions, conditions, regular expressions,
  lists, and condition aliases.
- [Packages & Scopes](guide/packages.md) - Match Nix packages with `exact` and
  `wildcard` scopes.
- [Groups & Inheritance](guide/groups.md) - Organize rules into groups with
  shared attributes.
- [Coexisting with Hand-Written Rules](guide/hand-written-rules.md) - Combine
  `opensnix` with raw `services.opensnitch.rules` definitions.
- [Configuration Options](reference/options.md) - Full generated reference for
  every option under `opensnix`.
