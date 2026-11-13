# Writing Rules

Each entry under `opensnix.rules.<name>` defines either a single rule or a
[rule group](groups.md). The attribute name is the rule identifier, and
`opensnix` prefixes every generated OpenSnitch rule name with `opensnix-`.

## Rule Actions

```nix
opensnix.rules = {
  lan.network = "10.0.0.0/8";
  telemetry.deny.host = "telemetry.example.com";
  ads.reject.domains = [
    "ads.example.com"
    "track.example.org"
  ];
};
```

An entry with no explicit `allow`, `deny`, or `reject` subkey uses
`opensnix.defaultAction`, which defaults to `"allow"`:

- `allow` permits matching connections.
- `deny` drops matching connections silently.
- `reject` drops matching connections and kills the socket via netlink so the
  application receives an immediate error instead of waiting for a timeout.

A rule may specify conditions either at the top level of the entry (using
`opensnix.defaultAction`) or inside at most one of `allow`, `deny`, or
`reject`. Setting `precedence = true;` on a rule gives it priority over
non-precedence rules in OpenSnitch.

## Regular Expressions

Condition keys that match a pattern rather than a single literal value - `host`,
`ip`, `dstIp`, `srcIp`, `port`, `dstPort`, `srcPort`, `processPath`,
`processCommand`, and the `domains` / `hosts` lists - accept a
`{ regexp = "..."; }` (or `{ regexp = [ ... ]; }` for domain lists) attribute
set in place of a plain value:

```nix
opensnix.rules.telemetry.deny.host.regexp = ".*[.]telemetry[.]example[.]com";
```

`opensnix` wraps every pattern in `^(?:<pattern>)$` automatically. Writing a
leading `^` or trailing `$` yourself is an evaluation error.

## Multi-Rule Array Expansions

While plural list conditions (`ports`, `ips`, `nets`, `domains`) match any value
within a single OpenSnitch rule, the user array fields (`users`, `userNames`,
and `userIds`) expand a single `opensnix.rules.<name>` entry into **one
generated OpenSnitch rule per element**:

- `users` and `userNames` generate rules named `opensnix-<rule>-user-<name>`,
  setting `userName = "<name>"` (`user.name`) on each rule.
- `userIds` generates rules named `opensnix-<rule>-userId-<id>`, setting
  `userId = <id>` (`user.id`) on each rule.

```nix
opensnix.rules.https = {
  users = [
    "alice"
    "bob"
  ];
  host = "example.com";
  port = 443;
};
```

The declaration above produces two OpenSnitch rules -
`opensnix-https-user-alice` and `opensnix-https-user-bob` - that share the
`host = "example.com"` and `port = 443` conditions alongside each user's
`user.name` condition.

When an array field is set on a [rule group](groups.md), it is inherited by the
group's leaf children and expands at each leaf (for example
`opensnix-<group>-<child>-user-<name>`).

Array expansions enforce the following rules at evaluation time:

- **One array field per rule**: A rule may specify at most one of `users`,
  `userNames`, or `userIds`.
- **No same-operand collision**: Combining `users` or `userNames` with `user`
  or `userName`, or combining `userIds` with `userId`, is an evaluation error.
- **Non-empty arrays**: An empty list (`users = [ ];`) is an evaluation error.
- **Unique generated rule names**: Duplicate elements
  (`users = [ "bob" "bob" ];`) or another rule whose name collides with an
  expanded name (`foo-user-bob` alongside `foo.users = [ "bob" ]`) raise a
  duplicate-rule-name error.

## Condition Aliases

Some condition keys are aliases of others and map to the same OpenSnitch
operand:

| Alias        | Canonical  | OpenSnitch Operand |
| ------------ | ---------- | ------------------ |
| `dstPort`    | `port`     | `dest.port`        |
| `dstPorts`   | `ports`    | `dest.port`        |
| `dstIp`      | `ip`       | `dest.ip`          |
| `dstNetwork` | `network`  | `dest.network`     |
| `user`       | `userName` | `user.name`        |
| `ifaceOut`   | `iface`    | `iface.out`        |
| `hosts`      | `domains`  | `lists.domains`    |

A rule may set at most one condition per operand. Combining an alias with its
canonical key (`domains` together with `hosts`) or two shapes of the same
operand (`port = 53` together with `ports = [ 53 853 ]`) is an evaluation
error: OpenSnitch ANDs an operator's children, so two conditions on the same
operand are always redundant or impossible to satisfy together.

Note that singular `host` (exact `dest.host`) is its own condition, distinct
from the `hosts` list alias (`lists.domains`).
