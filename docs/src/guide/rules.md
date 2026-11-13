# Writing Rules

Each entry under `opensnix.rules.<name>` defines either a single rule or a
[rule group](groups.md). The attribute name is the rule identifier, and
`opensnix` prefixes every generated OpenSnitch rule name with `opensnix-`.

Rule identifiers (including names produced by group and array expansion) must
start with an alphanumeric character and contain only `[A-Za-z0-9._-]`.
Characters such as `/` are rejected at evaluation time because each rule name
is linked as a filename into OpenSnitch's rules directory.

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
`reject`.

## Rule Precedence

Setting `precedence = true;` marks a rule as a priority rule in OpenSnitch:

```nix
opensnix.rules.trusted-dns = {
  allow = {
    ip = "9.9.9.9";
    port = 53;
  };
  precedence = true;
};
```

- When `precedence = true;`, a matching rule short-circuits OpenSnitch rule
  evaluation immediately, so an `allow` rule with precedence wins over any
  later matching `deny` rule (`deny` and `reject` rules already short-circuit
  in OpenSnitch).
- When `precedence` is unset (`null`, the default), the `precedence` field is
  omitted from the generated rule JSON.
- Setting `precedence = false;` emits `"precedence": false` explicitly, which
  allows a child rule to override `precedence = true;` inherited from an
  enclosing [rule group](groups.md).

## Combining Multiple Conditions

A rule with a single condition emits that condition's OpenSnitch operator
directly. When a rule sets two or more conditions (whether declared directly on
the rule, inside an `allow`/`deny`/`reject` wrapper, or inherited from a
[rule group](groups.md)), `opensnix` combines them into an OpenSnitch
`type = "list"` (`operand = "list"`) operator where **all** conditions must
match (logical AND):

```nix
opensnix.rules.api = {
  host = "api.example.com";
  port = 443;
  proto = "tcp";
};
```

Every rule must contain at least one condition; an empty rule fragment
(`opensnix.rules.foo = { };`) is an evaluation error.

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

## Plural List Conditions

Plural condition keys match any element in a list within a **single**
OpenSnitch rule (logical OR across the list's elements):

- **Port lists (`ports`, `dstPorts`, `srcPorts`)**: Compiled into a single
  `type = "regexp"` condition with an anchored alternation pattern on
  `dest.port` or `source.port` (for example `ports = [ 80 443 ];` renders to
  `^(?:80|443)$`).
- **Domain lists (`domains`, `hosts`)**: Written to a Nix store directory
  containing `domains.list` in hosts-file format (`0.0.0.0 <domain>` per line)
  for OpenSnitch's `lists.domains` `lists` operator.
- **Regexp domain lists (`domains.regexp`, `hosts.regexp`)**: Written to a Nix
  store directory containing `domains_regexp.list` (with each entry wrapped in
  `^(?:<pattern>)$`) for OpenSnitch's `lists.domains_regexp` `lists` operator.
- **IP and network lists (`ips`, `nets`)**: Written to a Nix store directory
  containing `ips.list` (`lists.ips`) or `nets.list` (`lists.nets`), one IP
  address or CIDR subnet per line.

```nix
opensnix.rules.dns-and-web = {
  ports = [
    53
    443
  ];
  domains = [
    "example.com"
    "example.org"
  ];
};
```

Passing an empty list (`[ ]`) to any plural list condition (including
`domains.regexp = [ ];`) is an evaluation error.

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

*(When used with `{ regexp = [ ... ]; }`, both `domains` and `hosts` map to
`lists.domains_regexp` instead of `lists.domains`.)*

A rule may set at most one condition per operand. Combining an alias with its
canonical key (`domains` together with `hosts`) or two shapes of the same
operand (`port = 53` together with `ports = [ 53 853 ]`) is an evaluation
error: OpenSnitch ANDs an operator's children, so two conditions on the same
operand are always redundant or impossible to satisfy together.

Note that singular `host` (`dest.host`), bare `domains`/`hosts`
(`lists.domains`), and regexp `domains.regexp`/`hosts.regexp`
(`lists.domains_regexp`) have distinct OpenSnitch operands and can be combined
in the same rule when needed.

## Network Subnets, Aliases & Protocols

- **`network` and `dstNetwork`**: Accept either a CIDR subnet (`"10.0.0.0/8"`)
  or an OpenSnitch network alias such as `"LAN"` or `"MULTICAST"` (`type =
  "network"`, `operand = "dest.network"`). They do not accept `{ regexp =
  "..."; }`.
- **`proto`**: Validated case-insensitively at evaluation time against the
  protocol strings OpenSnitch produces: `tcp`, `tcp6`, `udp`, `udp6`,
  `udplite`, `udplite6`, `sctp`, `sctp6`, `icmp`, and `icmp6`.
