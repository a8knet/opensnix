# Groups & Inheritance

Setting `rules` on an `opensnix.rules.<name>` entry turns that entry into a
rule group:

```nix
opensnix.rules.systemd-resolved = {
  userName = "systemd-resolve";
  rules = {
    dns = {
      network = "LAN";
      port = 53;
    };
    dnssec = {
      domains = [ "example.org" ];
      port = 853;
    };
  };
};
```

## How Inheritance Works

A group is a pure defaults container: **no OpenSnitch rule is emitted for the
group itself**, only for its leaf children (`opensnix-<group>-<child>`).

Every child rule inside `rules` inherits its parent group's:

- Top-level conditions (such as `userName`, `package`, `proto`, `iface`, etc.)
- Action wrapper (`allow`, `deny`, or `reject`) and the conditions inside it
- `precedence` flag (a child rule can undo a group's `precedence = true;` by
  setting `precedence = false;` explicitly)

When both a parent group and a child rule define the same attribute, the child
wins. The two child rules in the example above are rendered as
`opensnix-systemd-resolved-dns` and `opensnix-systemd-resolved-dnssec`, and
both carry `userName = "systemd-resolve"`.

Groups can nest to any depth (`opensnix-<parent>-<child>-<grandchild>`).
Operand collisions (for example a group setting `domains` and a child setting
its `hosts` alias) and duplicate rule names (for example a top-level `g-web`
rule alongside `g.rules.web`) are checked after group inheritance is resolved.
An empty `rules = { };` group is an evaluation error.

## Package Option Merging Across Groups

When both a parent group and a child rule set `package`, unset (`null`)
submodule fields on the child are dropped before merging so partial `package`
definitions combine cleanly while explicit child settings override the parent:

```nix
opensnix.rules = {
  systemd = {
    package.regexp = "systemd-[0-9]+[.][0-9]+";
    rules = {
      resolved = {
        package.path = "/lib/systemd/systemd-resolved";
        port = 53;
      };
      timesyncd = {
        package.path = "/lib/systemd/systemd-timesyncd";
        port = 123;
      };
    };
  };

  browsers = {
    package = {
      value = pkgs.firefox;
      wrapped = true;
    };
    rules = {
      web.port = 443;
      unwrapped.package.wrapped = false;
    };
  };
};
```

In `systemd`, each child supplies its own `package.path` and inherits the
group's `package.regexp`. In `browsers`, `web` inherits `wrapped = true;` while
`unwrapped` explicitly overrides it with `wrapped = false;` (or overrides a
group's `scope = "wildcard";` with `scope = "exact";`).
