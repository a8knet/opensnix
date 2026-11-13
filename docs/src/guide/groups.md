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

Every child rule inside `rules` inherits its parent group's:

- Top-level conditions (such as `userName`, `package`, `proto`, `iface`, etc.)
- Action wrapper (`allow`, `deny`, or `reject`) and the conditions inside it
- `precedence` flag (a child rule can undo a group's `precedence = true;` by
  setting `precedence = false;` explicitly)

When both a parent group and a child rule define the same attribute, the child
wins. The two child rules in the example above are rendered as
`opensnix-systemd-resolved-dns` and `opensnix-systemd-resolved-dnssec`, and
both carry `userName = "systemd-resolve"`.

Groups can nest to any depth (`opensnix-<parent>-<child>-<grandchild>`). An
empty `rules = { };` group is an evaluation error.

## Package Option Merging Across Groups

When a parent group sets `package` (for example `package.scope = "wildcard";`
or `package.wrapped = true;`) and a child rule supplies its own `package` (such
as a bare `package = pkgs.firefox;`), the child inherits the parent's `scope`
and `wrapped` settings unless the child explicitly overrides them (for example
`scope = "exact";` or `wrapped = false;`).
