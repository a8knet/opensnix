{
  lib,
  pkgsUtils,
}:
let
  utils = import ./utils.nix;
  types = import ./types.nix { inherit lib; };

  # Nix base32 (nix32) hash alphabet: 0-9a-z without e, o, t, u.
  storeHashClass = "[0-9abcdfghijklmnpqrsvwxyz]{32}";

  # Store path without its '/nix/store/<hash>-' prefix: the directory name a
  # package's files are reported under, which can differ from `.name`.
  storeDirName = path: builtins.head (builtins.match "/nix/store/${storeHashClass}-(.*)" path);

  toWrapped = path: "${dirOf path}/.${baseNameOf path}-wrapped";

  # String type that rejects leading '^' or trailing '$' anchors, since the
  # wrapper adds '^(?:<pattern>)$' around the pattern. The group is essential: RE2
  # binds alternation looser than anchors, so bare ^80|443$ parses as
  # (^80)|(443$) and would match 8080 or 1443; ^(?:80|443)$ matches only
  # 80 or 443.
  regexpStrType =
    lib.types.addCheck lib.types.str (v: !(lib.hasPrefix "^" v || lib.hasSuffix "$" v))
    // {
      description = "string without leading '^' or trailing '$'";
      descriptionClass = "noun";
    };

  listToRegexp = values: "(?:" + (lib.concatStringsSep "|" (map builtins.toString values)) + ")";

  domainsSpec = {
    type = "lists";
    operand = "lists.domains";
    valueType = lib.types.listOf lib.types.str;
    fileName = "domains.list";
    format = values: lib.concatStringsSep "\n" (map (d: "0.0.0.0 ${d}") values);
    regexpElementType = regexpStrType;
    regexpOperand = "lists.domains_regexp";
    regexpFileName = "domains_regexp.list";
    regexpFormat = values: lib.concatStringsSep "\n" (map (d: "^(?:${d})$") values);
    description = ''
      Destination domain list written as a hosts-formatted `domains.list`
      (`lists.domains` `lists` condition), or `{ regexp = [ ... ]; }` written as
      `domains_regexp.list` (`lists.domains_regexp`).
    '';
    example = [
      "example.com"
      "example.org"
    ];
  };

  # Package specification: either a bare package or an attrset with options.
  # Forms:
  #   - Bare package: pkgs.foobar (coerced to { value = pkgs.foobar; })
  #   - { value = pkgs.foobar; } -> realpath(lib.getExe value)
  #   - { value = pkgs.foobar; wrapped = true; } -> toWrapped(realpath(lib.getExe value))
  #   - { value = pkgs.foobar; path = "/bin/foo"; } -> "${lib.getBin value}${path}"
  #   - { regexp = "foo-[0-9]+"; path = "/bin/foo"; } -> regexp pattern
  #   - Wildcard scope + value: store-directory regexp over the bin output's
  #     directory name (multi-output packages append the output to it), with a
  #     trailing '-wrapped' stripped (the real binaries live in the unwrapped
  #     package's store directory).
  packageType =
    let
      packageAttrSetType = lib.types.submodule {
        _file = ./rules.nix;
        options = {
          value = lib.mkOption {
            type = lib.types.nullOr lib.types.package;
            default = null;
            example = lib.literalExpression "pkgs.firefox";
            description = "Package to resolve (mutually exclusive with `regexp`).";
          };
          wrapped = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            example = true;
            description = ''
              Apply `toWrapped` transformation (requires `value`, incompatible
              with `path`). `null` inherits from the enclosing group; an
              explicit `false` overrides a group's `true`.
            '';
          };
          path = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "/bin/curl";
            description = ''
              Explicit path within package (requires `value` or `regexp`,
              incompatible with `wrapped`).
            '';
          };
          regexp = lib.mkOption {
            type = lib.types.nullOr regexpStrType;
            default = null;
            example = "python3-[0-9.]+";
            description = ''
              Package store directory regexp (mutually exclusive with `value`,
              requires `path` in `exact` scope).
            '';
          };
          scope = lib.mkOption {
            type = lib.types.nullOr types.packageScope;
            default = null;
            example = "wildcard";
            description = ''
              Override `defaultPackageScope` for this rule. `null` inherits from
              the group or `defaultPackageScope`; to undo a group's scope set an
              explicit value.
            '';
          };
        };
      };
    in
    lib.types.coercedTo lib.types.package (v: { value = v; }) packageAttrSetType;

  # Map a condition field to its OpenSnitch operator spec.
  # The `data` is filled in by mkOperator from the user-supplied value.
  # Conditions with `regexpType` support `{ regexp = "..."; }` syntax.
  # List conditions with `regexpElementType` support `{ regexp = [...]; }` syntax.
  conditionMap = {
    host = {
      type = "simple";
      operand = "dest.host";
      regexpType = regexpStrType;
      description = ''
        Destination hostname (`dest.host`), or `{ regexp = "..."; }` for an
        anchored regular expression.
      '';
      example = "example.com";
    };

    port = {
      type = "simple";
      operand = "dest.port";
      valueType = lib.types.ints.u16;
      regexpType = regexpStrType;
      description = ''
        Destination port number (`dest.port`), or `{ regexp = "..."; }` for an
        anchored regular expression.
      '';
      example = 443;
    };
    dstPort = {
      type = "simple";
      operand = "dest.port";
      valueType = lib.types.ints.u16;
      regexpType = regexpStrType;
      aliasOf = "port";
      description = ''
        Destination port number (`dest.port`), or `{ regexp = "..."; }` for an
        anchored regular expression.
      '';
      example = 443;
    };
    srcPort = {
      type = "simple";
      operand = "source.port";
      valueType = lib.types.ints.u16;
      regexpType = regexpStrType;
      description = ''
        Source port number (`source.port`), or `{ regexp = "..."; }` for an
        anchored regular expression.
      '';
      example = 5353;
    };

    ports = {
      type = "regexp";
      operand = "dest.port";
      valueType = lib.types.listOf lib.types.ints.u16;
      inherit listToRegexp;
      description = ''
        List of destination port numbers combined into an anchored alternation
        regexp (`dest.port`).
      '';
      example = [
        80
        443
      ];
    };
    dstPorts = {
      type = "regexp";
      operand = "dest.port";
      valueType = lib.types.listOf lib.types.ints.u16;
      aliasOf = "ports";
      inherit listToRegexp;
      description = ''
        List of destination port numbers combined into an anchored alternation
        regexp (`dest.port`).
      '';
      example = [
        80
        443
      ];
    };
    srcPorts = {
      type = "regexp";
      operand = "source.port";
      valueType = lib.types.listOf lib.types.ints.u16;
      inherit listToRegexp;
      description = ''
        List of source port numbers combined into an anchored alternation
        regexp (`source.port`).
      '';
      example = [
        67
        68
      ];
    };

    userName = {
      type = "simple";
      operand = "user.name";
      description = ''
        Owner username of the process initiating the connection (`user.name`).
      '';
      example = "systemd-resolve";
    };
    user = {
      type = "simple";
      operand = "user.name";
      aliasOf = "userName";
      description = ''
        Owner username of the process initiating the connection (`user.name`).
      '';
      example = "systemd-resolve";
    };
    userId = {
      type = "simple";
      operand = "user.id";
      valueType = lib.types.ints.unsigned;
      description = ''
        Numeric UID of the process initiating the connection (`user.id`).
      '';
      example = 1000;
    };

    ip = {
      type = "simple";
      operand = "dest.ip";
      regexpType = regexpStrType;
      description = ''
        Destination IP address (`dest.ip`), or `{ regexp = "..."; }` for an
        anchored regular expression.
      '';
      example = "9.9.9.9";
    };
    dstIp = {
      type = "simple";
      operand = "dest.ip";
      regexpType = regexpStrType;
      aliasOf = "ip";
      description = ''
        Destination IP address (`dest.ip`), or `{ regexp = "..."; }` for an
        anchored regular expression.
      '';
      example = "9.9.9.9";
    };
    srcIp = {
      type = "simple";
      operand = "source.ip";
      regexpType = regexpStrType;
      description = ''
        Source IP address (`source.ip`), or `{ regexp = "..."; }` for an
        anchored regular expression.
      '';
      example = "192.168.1.10";
    };

    network = {
      type = "network";
      operand = "dest.network";
      description = ''
        Destination CIDR subnet or OpenSnitch network alias such as `"LAN"` or
        `"MULTICAST"` (`dest.network` `network` condition).
      '';
      example = "10.0.0.0/8";
    };
    dstNetwork = {
      type = "network";
      operand = "dest.network";
      aliasOf = "network";
      description = ''
        Destination CIDR subnet or OpenSnitch network alias such as `"LAN"` or
        `"MULTICAST"` (`dest.network` `network` condition).
      '';
      example = "10.0.0.0/8";
    };

    proto = {
      type = "simple";
      operand = "protocol";
      valueType = types.protocol;
      description = ''
        Transport or network protocol matched case-insensitively (`protocol`).
      '';
      example = "udp";
    };

    processPath = {
      type = "simple";
      operand = "process.path";
      regexpType = regexpStrType;
      description = ''
        Executable path of the process (`process.path`), or
        `{ regexp = "..."; }` for an anchored regular expression. Cannot be
        combined with `package`.
      '';
      example = "/run/current-system/sw/bin/curl";
    };
    processCommand = {
      type = "simple";
      operand = "process.command";
      regexpType = regexpStrType;
      description = ''
        Full command line of the process (`process.command`), or
        `{ regexp = "..."; }` for an anchored regular expression.
      '';
      example = {
        regexp = "python3 -m http[.]server.*";
      };
    };

    iface = {
      type = "simple";
      operand = "iface.out";
      description = "Outbound network interface name (`iface.out`).";
      example = "wlan0";
    };
    ifaceIn = {
      type = "simple";
      operand = "iface.in";
      description = "Inbound network interface name (`iface.in`).";
      example = "eth0";
    };
    ifaceOut = {
      type = "simple";
      operand = "iface.out";
      aliasOf = "iface";
      description = "Outbound network interface name (`iface.out`).";
      example = "wlan0";
    };

    ips = {
      type = "lists";
      operand = "lists.ips";
      valueType = lib.types.listOf lib.types.str;
      fileName = "ips.list";
      format = values: lib.concatStringsSep "\n" values;
      description = ''
        Destination IP address list written to `ips.list` (`lists.ips` `lists`
        condition).
      '';
      example = [
        "1.1.1.1"
        "9.9.9.9"
      ];
    };

    nets = {
      type = "lists";
      operand = "lists.nets";
      valueType = lib.types.listOf lib.types.str;
      fileName = "nets.list";
      format = values: lib.concatStringsSep "\n" values;
      description = ''
        Destination CIDR network list written to `nets.list` (`lists.nets`
        `lists` condition).
      '';
      example = [
        "10.0.0.0/8"
        "192.168.0.0/16"
      ];
    };

    domains = domainsSpec;
    hosts = domainsSpec // {
      aliasOf = "domains";
    };
  };

  regexpSubmoduleType =
    innerType:
    (lib.types.submodule {
      options = {
        regexp = lib.mkOption {
          type = innerType;
          description = ".regexp value must be a string";
        };
      };
    })
    // {
      description = "{ regexp = ${innerType.description}; }";
      descriptionClass = "noun";
      getSubOptions = _: { };
    };

  # Typed option attrs for a single rule fragment, derived from `conditionMap`
  # so the set of condition keys and their Nix value types live in exactly one
  # place. A spec without `valueType` defaults to a string; numeric conditions
  # declare a range-checked type (ports: `lib.types.ints.u16`, user ids:
  # `lib.types.ints.unsigned`, protocol: `types.protocol`). Conditions with
  # `regexpType` support `{ regexp = "..."; }` syntax.
  conditionsOptions = lib.mapAttrs (
    _: spec:
    let
      baseType = spec.valueType or lib.types.str;
      optionType =
        if spec ? regexpType then
          lib.types.nullOr (lib.types.either baseType (regexpSubmoduleType spec.regexpType))
        else if spec ? regexpElementType then
          lib.types.nullOr (
            lib.types.either baseType (regexpSubmoduleType (lib.types.listOf spec.regexpElementType))
          )
        else
          lib.types.nullOr baseType;
    in
    lib.mkOption (
      {
        type = optionType;
        default = null;
        description =
          (lib.optionalString (spec ? aliasOf) "Alias for `${spec.aliasOf}`. ") + spec.description;
      }
      // lib.optionalAttrs (spec ? example) {
        inherit (spec) example;
      }
    )
  ) conditionMap;

  # Map array-expansion fields to their condition key and rule-name suffix.
  arrayExpansionMap = {
    users = {
      conditionKey = "user";
      suffix = "user";
      example = [
        "alice"
        "bob"
      ];
    };
    userNames = {
      conditionKey = "userName";
      suffix = "user";
      example = [
        "alice"
        "bob"
      ];
    };
    userIds = {
      conditionKey = "userId";
      suffix = "userId";
      example = [
        1000
        1001
      ];
    };
  };

  # Effective operand of a condition key; lists values in `{ regexp = ...; }`
  # form render to their own operand.
  operandOf =
    key: value:
    let
      spec = conditionMap.${key};
    in
    if spec.type == "lists" && builtins.isAttrs value then spec.regexpOperand else spec.operand;

  # First operand claimed by two fragment keys (aliases included), or null.
  # Array fields count as their condition key.
  findOperandCollision =
    fragment:
    let
      arrayFieldNames = builtins.attrNames (
        lib.filterAttrs (k: _: (fragment.${k} or null) != null) arrayExpansionMap
      );
      entries =
        map (k: {
          label = k;
          operand = operandOf k fragment.${k};
        }) (lib.intersectLists (builtins.attrNames fragment) (builtins.attrNames conditionMap))
        ++ map (k: {
          label = k;
          operand = operandOf arrayExpansionMap.${k}.conditionKey [ ];
        }) arrayFieldNames;
      collisions = lib.filterAttrs (_: es: builtins.length es > 1) (lib.groupBy (e: e.operand) entries);
      first = builtins.head (builtins.attrNames collisions);
    in
    if collisions == { } then
      null
    else
      {
        operand = first;
        labels = builtins.sort builtins.lessThan (map (e: e.label) collisions.${first});
      };

  arrayOptions = lib.mapAttrs (
    _fieldName: spec:
    let
      valueType = conditionMap.${spec.conditionKey}.valueType or lib.types.str;
    in
    lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf valueType);
      default = null;
      inherit (spec) example;
      description = ''
        Expand one rule per element into separate OpenSnitch rules named
        `opensnix-<rule>-${spec.suffix}-<value>`, setting `${spec.conditionKey}`
        on each.
      '';
    }
  ) arrayExpansionMap;

  packageOption = lib.mkOption {
    type = lib.types.nullOr packageType;
    default = null;
    example = lib.literalExpression "pkgs.curl";
    description = ''
      Resolve a Nix package to a `process.path` condition. Accepts a bare
      package (coerced to `{ value = <pkg>; }`) or an attribute set of package
      options.
    '';
  };

  conditionsTypeWithArrays = lib.types.submodule {
    options = conditionsOptions // arrayOptions // { package = packageOption; };
  };

  precedenceOption = lib.mkOption {
    type = lib.types.nullOr lib.types.bool;
    default = null;
    example = true;
    description = ''
      OpenSnitch rule precedence ("Priority rule"). When `true`, a matching
      rule short-circuits evaluation immediately, so an `allow` rule with
      precedence wins over any later matching `deny`. When `null` (default),
      the field is omitted from the generated JSON. Has no additional effect
      on `deny`/`reject` rules, which already short-circuit.
    '';
  };

  # Shared option set for rule entries: the `allow`/`deny`/`reject` wrappers,
  # the internally managed `precedence`, every condition key, and the array
  # expansion fields.
  ruleOptions = {
    allow = lib.mkOption {
      type = lib.types.nullOr conditionsTypeWithArrays;
      default = null;
      visible = "shallow";
      description = "Wrap a rule fragment with the `allow` action.";
    };
    deny = lib.mkOption {
      type = lib.types.nullOr conditionsTypeWithArrays;
      default = null;
      visible = "shallow";
      description = "Wrap a rule fragment with the `deny` action.";
    };
    reject = lib.mkOption {
      type = lib.types.nullOr conditionsTypeWithArrays;
      default = null;
      visible = "shallow";
      description = "Wrap a rule fragment with the `reject` action.";
    };
    precedence = precedenceOption;
  }
  // conditionsOptions
  // arrayOptions
  // {
    package = packageOption;
  };

  # Typed schema for a top-level `opensnix.rules` entry: either a leaf rule
  # (bare fragment, or wrapped in `allow` / `deny` / `reject`), or a group carrying
  # shared defaults plus a nested attrset of child rules. The type is
  # self-referential: child entries may themselves be groups, so grouping
  # nests to unlimited depth, while remaining fully typed at every level.
  groupedRuleType = lib.types.submodule {
    _file = ./rules.nix;
    options = ruleOptions // {
      rules = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf groupedRuleType);
        default = null;
        visible = "shallow";
        description = ''
          Turn this entry into a group. Its condition fields, `allow`/`deny`/`reject`
          wrapper, and `precedence` are inherited by every child rule (child
          values win); generated rules are named `<group>-<child>`. Children
          may nest further groups. Setting `rules` to an empty attrset is an
          error.
        '';
      };
    };
  };

  # Build a single child operator for one condition key.
  mkChild =
    frag: key:
    let
      spec = conditionMap.${key};
      raw = frag.${key};
      isRegexp = builtins.isAttrs raw;
      value = if isRegexp then raw.regexp else raw;
    in
    if spec.type == "lists" then
      if isRegexp then
        let
          content = spec.regexpFormat value;
          dir = pkgsUtils.writeTextDir spec.regexpFileName content;
        in
        {
          type = "lists";
          operand = spec.regexpOperand;
          data = dir;
        }
      else
        let
          content = spec.format value;
          dir = pkgsUtils.writeTextDir spec.fileName content;
        in
        {
          inherit (spec) type operand;
          data = dir;
        }
    else if spec ? listToRegexp then
      {
        type = "regexp";
        inherit (spec) operand;
        data = "^" + (spec.listToRegexp value) + "$";
      }
    else
      {
        type = if isRegexp then "regexp" else spec.type;
        inherit (spec) operand;
        data = if isRegexp then "^(?:${builtins.toString value})$" else builtins.toString value;
      };

  # Build the operator for a rule fragment.
  #
  # A fragment with a single condition yields that condition's operator
  # directly. A fragment with several conditions yields a list operator
  # (type = "list", operand = "list") whose children are combined with AND
  # (OpenSnitch's list type is inherently an AND of all its children).
  mkOperator =
    frag:
    let
      names = builtins.attrNames frag;
      children = map (mkChild frag) names;
    in
    if builtins.length names == 0 then
      builtins.throw "opensnix: a rule must contain at least one condition, got an empty fragment."
    else if builtins.length names == 1 then
      builtins.head children
    else
      {
        type = "list";
        operand = "list";
        list = children;
      };

  # Build a single OpenSnitch rule for the given name.
  # `frag` is the user-provided single-condition fragment; the internally
  # managed fields are always set here and override anything the user might
  # have tried to supply (there is intentionally no generic pass-through).
  mkRule =
    name: action: precedence: timestamp: frag:
    {
      inherit action;
      created = timestamp;
      updated = timestamp;
      name = "opensnix-${name}";
      enabled = true;
      duration = "always";
      operator = mkOperator frag;
    }
    // lib.optionalAttrs (precedence != null) {
      inherit precedence;
    };

  resolvePackageValue =
    frag: pkg:
    let
      hasPath = pkg.path or null != null;
    in
    removeAttrs frag [ "package" ]
    // (
      if hasPath then
        { processPath = "${lib.getBin pkg.value}${pkg.path}"; }
      else
        { processPath = pkgsUtils.realpath (lib.getExe pkg.value); }
    );

  resolvePackageValueOrWrapped =
    name: frag: pkg:
    let
      hasWrapped = (pkg.wrapped or false) == true;
      hasPath = pkg.path or null != null;
    in
    if hasWrapped && hasPath then
      builtins.throw "opensnix: rule '${name}' cannot specify both 'wrapped = true' and 'path'."
    else if hasWrapped then
      removeAttrs frag [ "package" ]
      // {
        processPath = toWrapped (pkgsUtils.realpath (lib.getExe pkg.value));
      }
    else
      resolvePackageValue frag pkg;

  resolvePackageRegexp =
    name: frag: pkg:
    let
      hasPath = pkg.path or null != null;
    in
    if !hasPath then
      builtins.throw "opensnix: rule '${name}' with 'regexp' must specify 'path'."
    else
      removeAttrs frag [ "package" ]
      // {
        processPath = {
          regexp = "/nix/store/${storeHashClass}-(?:${pkg.regexp})${lib.escapeRegex pkg.path}";
        };
      };

  resolvePackageWildcard =
    name: frag: pkg:
    let
      hasPath = pkg.path or null != null;
      hasWrapped = (pkg.wrapped or false) == true;
      hasRegexp = pkg ? regexp && pkg.regexp != null;
      hasValue = pkg ? value && pkg.value != null;
      pattern =
        if hasRegexp then
          pkg.regexp
        else if hasValue then
          # The bin output's store directory is where executables run from, and
          # it can differ from `.name` (multi-output: 'curl-8.23.0-bin'). A
          # trailing '-wrapped' is dropped: the real binaries live unwrapped.
          lib.escapeRegex (lib.removeSuffix "-wrapped" (storeDirName (lib.getBin pkg.value).outPath))
        else
          builtins.throw "opensnix: rule '${name}' package must specify either 'value' or 'regexp'.";
    in
    if hasPath then
      builtins.throw "opensnix: rule '${name}' with wildcard scope cannot specify 'path'."
    else if hasWrapped then
      builtins.throw "opensnix: rule '${name}' with wildcard scope cannot specify 'wrapped'."
    else
      removeAttrs frag [ "package" ]
      // {
        processPath = {
          regexp = "/nix/store/${storeHashClass}-(?:${pattern})/.*";
        };
      };

  resolvePackageExact =
    name: frag: pkg:
    let
      hasRegexp = pkg ? regexp && pkg.regexp != null;
      hasValue = pkg ? value && pkg.value != null;
    in
    if hasRegexp then
      resolvePackageRegexp name frag pkg
    else if hasValue then
      resolvePackageValueOrWrapped name frag pkg
    else
      builtins.throw "opensnix: rule '${name}' package must specify either 'value' or 'regexp'.";

  resolvePackage =
    name: frag: defaultScope:
    let
      hasPackage = frag ? package && frag.package != null;
    in
    if !hasPackage then
      frag
    else
      let
        pkg = frag.package;
        scope = if pkg.scope or null != null then pkg.scope else defaultScope;
        hasProcessPath = frag ? processPath && frag.processPath != null;
      in
      if hasProcessPath then
        builtins.throw "opensnix: rule '${name}' cannot specify both 'package' and 'processPath'."
      else if scope == "wildcard" then
        resolvePackageWildcard name frag pkg
      else
        resolvePackageExact name frag pkg;

  # Turn the opensnix.rules attrset into an attrset of full OpenSnitch rules,
  # shaped exactly like `services.opensnitch.rules` (attrsOf freeform).
  #
  # Each entry may be:
  #   - a bare single-condition fragment  -> action taken from defaultAction
  #   - { allow  = <fragment> } -> action = "allow"
  #   - { deny   = <fragment> } -> action = "deny"
  #   - { reject = <fragment> } -> action = "reject"
  #   - a group: any of the above plus `rules = { <child> = <entry>; }`; the
  #     group is a pure defaults container (no rule is emitted for the group
  #     itself) and yields one rule per leaf named `<group>-<child>-...`.
  #     Groups nest to unlimited depth.
  mkRules =
    {
      defaultAction,
      defaultPackageScope,
      rules,
      timestamp,
    }:
    let
      # Resolve the actual condition fragment and action for an entry, handling
      # the `allow`/`deny`/`reject` wrappers and the typed schema's null
      # defaults.
      # `action` is null when no explicit wrapper is present, so group children
      # can fall back to the group wrapper and only then to `defaultAction`.
      resolve =
        entry:
        let
          wrappers = lib.filter (n: entry.${n} != null) [
            "allow"
            "deny"
            "reject"
          ];
          wrapped =
            if lib.length wrappers > 1 then
              builtins.throw "opensnix: a rule cannot specify more than one of 'allow', 'deny', 'reject'."
            else if wrappers == [ ] then
              {
                fragment = removeAttrs entry [
                  "allow"
                  "deny"
                  "reject"
                  "precedence"
                  "rules"
                ];
                action = null;
              }
            else
              {
                fragment = entry.${lib.head wrappers};
                action = lib.head wrappers;
              };
        in
        wrapped
        // {
          inherit (entry) precedence;
          fragment = lib.filterAttrs (_: v: v != null) wrapped.fragment;
        };

      # Merge a group fragment with a child fragment; child values win.
      # `package` is special-cased: unset submodule fields (`null`) are
      # dropped before merging so partial overrides such as group
      # `package.regexp` + child `package.path` combine, while explicitly
      # set fields (including `wrapped = false`) override the group value.
      mergeFragments =
        parent: child:
        let
          bothPackages = (parent.package or null != null) && (child.package or null != null);
          childPackage = lib.filterAttrs (_: v: v != null) child.package;
        in
        lib.recursiveUpdate parent (if bothPackages then child // { package = childPackage; } else child);

      # Neutral ancestor context for top-level entries.
      emptyInherited = {
        fragment = { };
        action = null;
        precedence = null;
      };

      # Recursively expand one entry into rule records, threading the merged
      # fragment, action, and precedence inherited from ancestor groups down
      # to every leaf. Plain entries yield themselves; groups (non-null
      # `rules`) yield one record set per child, named `<group>-<child>`.
      expandEntry =
        inherited: name: entry:
        let
          r = resolve entry;
          node = {
            inherit name;
            fragment = mergeFragments inherited.fragment r.fragment;
            action = if r.action != null then r.action else inherited.action;
            precedence = if r.precedence != null then r.precedence else inherited.precedence;
          };
        in
        if entry.rules or null == null then
          [ node ]
        else if entry.rules == { } then
          builtins.throw "opensnix: group '${name}' has an empty 'rules' attrset; add at least one child rule or remove the group."
        else
          lib.concatLists (
            lib.mapAttrsToList (childName: expandEntry node "${name}-${childName}") entry.rules
          );

      expandArrays =
        name: r:
        let
          inherit (r) fragment;
          arrayFields = lib.filterAttrs (k: _: (fragment.${k} or null) != null) arrayExpansionMap;
          arrayFieldNames = builtins.attrNames arrayFields;
          isEmptyList =
            k: v:
            let
              spec = conditionMap.${k} or { };
            in
            ((spec.type or "") == "lists" && ((v == [ ]) || (builtins.isAttrs v && (v.regexp or null) == [ ])))
            || (spec ? listToRegexp && v == [ ]);
          listFields = lib.filterAttrs isEmptyList fragment;
          listFieldNames = builtins.attrNames listFields;
          collision = findOperandCollision fragment;
        in
        if builtins.length listFieldNames > 0 then
          builtins.throw "opensnix: rule '${name}' has empty list for '${builtins.head listFieldNames}'."
        else if builtins.length arrayFieldNames > 1 then
          builtins.throw "opensnix: rule '${name}' specifies multiple array fields (${builtins.concatStringsSep ", " arrayFieldNames}); only one is allowed."
        else if collision != null then
          builtins.throw "opensnix: rule '${name}' specifies multiple conditions for operand '${collision.operand}' (${builtins.concatStringsSep ", " collision.labels}); only one is allowed."
        else if arrayFieldNames == [ ] then
          [
            {
              inherit name fragment;
              inherit (r) action precedence;
            }
          ]
        else
          let
            fieldName = builtins.head arrayFieldNames;
            spec = arrayFields.${fieldName};
            values = fragment.${fieldName};
          in
          if values == [ ] then
            builtins.throw "opensnix: rule '${name}' has empty array for '${fieldName}'."
          else
            map (value: {
              name = "${name}-${spec.suffix}-${builtins.toString value}";
              fragment = (removeAttrs fragment [ fieldName ]) // {
                ${spec.conditionKey} = value;
              };
              inherit (r) action precedence;
            }) values;

      expandedEntries = lib.concatLists (
        lib.mapAttrsToList (
          name: entry:
          lib.concatLists (
            map (
              r:
              expandArrays r.name (
                r
                // {
                  fragment = resolvePackage r.name r.fragment defaultPackageScope;
                  action = if r.action != null then r.action else defaultAction;
                }
              )
            ) (expandEntry emptyInherited name entry)
          )
        ) rules
      );

      dups = lib.filterAttrs (_: vs: builtins.length vs > 1) (lib.groupBy (e: e.name) expandedEntries);
      invalidNames = lib.filter (n: !utils.isValidRuleName n) (map (e: e.name) expandedEntries);
    in
    if !utils.isRfc3339UTC timestamp then
      builtins.throw "opensnix: timestamp '${timestamp}' is not a valid RFC3339 UTC date-time (expected YYYY-MM-DDTHH:MM:SSZ)."
    else if invalidNames != [ ] then
      builtins.throw "opensnix: invalid rule name '${builtins.head invalidNames}'; rule names must start with an alphanumeric character and may only contain [A-Za-z0-9._-]."
    else if dups != { } then
      builtins.throw "opensnix: duplicate rule name '${builtins.head (lib.attrNames dups)}' generated; check for duplicate values in array fields or conflicting rule names."
    else
      builtins.listToAttrs (
        map (
          e:
          let
            rule = mkRule e.name e.action e.precedence timestamp e.fragment;
          in
          lib.nameValuePair rule.name rule
        ) expandedEntries
      );
in
{
  inherit
    mkRules
    groupedRuleType
    ;
}
