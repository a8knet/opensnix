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

## Lists vs. Multi-Rule Array Expansions

- **Plural list conditions** (`ports`, `dstPorts`, `srcPorts`, `ips`, `nets`,
  `domains`, `hosts`) match any value in the list within a single OpenSnitch
  rule (via an alternation regexp for ports or a generated list directory for
  IPs, CIDR nets, and domains).
- **Multi-rule array expansions** (`users`, `userNames`, `userIds`) expand one
  rule entry into separate OpenSnitch rules named
  `opensnix-<rule>-user-<value>` or `opensnix-<rule>-uid-<value>`, one per
  element.

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
