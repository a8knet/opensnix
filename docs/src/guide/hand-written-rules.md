# Coexisting with Hand-Written Rules

`opensnix` writes its generated rules into `services.opensnitch.rules`, the
same option used for hand-written OpenSnitch rules in NixOS, and prefixes every
generated rule name with `opensnix-`. Because the two sources merge by rule
name, adding a rule by hand alongside `opensnix` works as usual:

```nix
{
  services.opensnitch.rules."my-own-rule" = {
    name = "my-own-rule";
    action = "deny";
    enabled = true;
    duration = "always";
    operator = {
      type = "simple";
      operand = "process.path";
      data = "/bin/bar";
    };
  };
}
```

## Collision Detection

Because NixOS merges `services.opensnitch.rules` per rule name, defining a
hand-written key whose name matches an `opensnix-<name>` rule interacts with
the generated definition in one of two ways:

- **Conflicting fields (evaluation error)**: Setting a field that `opensnix`
  also sets (for example `action` on `opensnix-foo`) raises a standard NixOS
  conflicting-definition error. Drop the `opensnix` rule, or override the field
  explicitly with `lib.mkForce`.
- **Additional fields (evaluation warning)**: Setting a field that `opensnix`
  does not set (for example `precedence` when `opensnix` left it at `false`)
  modifies the generated rule. `opensnix` detects any difference between its
  rendered rule and the final `config.services.opensnitch.rules.<name>` value
  and emits an evaluation warning listing the affected rule names.

`opensnix` deliberately keeps these two behaviors: conflicting definitions stay
loud, and non-conflicting overrides follow standard NixOS module merge rules
while surfacing a warning.
