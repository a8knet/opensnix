# Packages & Scopes

The `package` option on a rule turns a Nix package into an OpenSnitch
`process.path` condition. It accepts either a bare package (coerced to
`{ value = <pkg>; }`) or an attribute set with `value`, `scope`, `wrapped`,
`path`, or `regexp`.

```nix
opensnix.rules = {
  curl = {
    package = pkgs.curl;
    port = 443;
  };

  firefox.package = {
    value = pkgs.firefox;
    scope = "wildcard";
  };
};
```

## Exact vs. Wildcard Scope

Package resolution supports two scopes, configured globally via
`opensnix.defaultPackageScope` (default `"exact"`) or per-rule via
`package.scope`:

- **`exact`**: Resolves to a single executable path inside the Nix store. By
  default, `opensnix` resolves `lib.getExe value` through `realpath` so wrapper
  symlinks point to the real store path.
- **`wildcard`**: Matches every binary inside the package's store directory via
  a regular expression anchored at the store directory of the package's `bin`
  output (a multi-output package keeps its executables in a directory like
  `curl-8.23.0-bin`, and any trailing `-wrapped` suffix on the store directory
  is stripped so unwrapped binaries match).

## Evaluation & Import-From-Derivation (IFD)

Resolving `lib.getExe value` in `exact` scope without an explicit `path` runs
`realpath` in a tiny derivation (import-from-derivation), which builds the
package at evaluation time if it is not already in the local store or binary
cache.

Setting `package.path` (for example `path = "/bin/curl";`) or using
`scope = "wildcard"` avoids import-from-derivation entirely because both only
inspect the store path string.

## Wrapped Executables & Custom Paths

- **`wrapped = true`**: Applies `toWrapped` to the resolved executable path
  (converting `/bin/foo` to `/bin/.foo-wrapped`) for Nixpkgs packages whose
  entry point is a shell wrapper around `.foo-wrapped`. Incompatible with
  `path` and `scope = "wildcard"`.
- **`path = "/bin/..."`**: Concatenates `${lib.getBin value}${path}` directly
  (or matches `${path}` inside a `regexp` store directory in `exact` scope).
- **`regexp = "python3-[0-9.]+"`**: Matches any store directory whose name
  after the 32-character Nix store hash matches the pattern. Requires `path` in
  `exact` scope.

Because `package` resolves to a `process.path` condition, a rule cannot set
both `package` and `processPath`. See [Groups & Inheritance](groups.md) for how
partial `package` attributes merge across rule groups.
