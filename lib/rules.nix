{
  lib,
  pkgsUtils,
  types,
}:
let
  utils = import ./utils.nix;
  inherit (types) packageScopeType;

  toWrapped = path: "${dirOf path}/.${baseNameOf path}-wrapped";

  # String type that rejects leading '^' or trailing '$' anchors, since the
  # wrapper automatically adds them for regexp conditions.
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
    regexpFormat = values: lib.concatStringsSep "\n" (map (d: "^${d}$") values);
  };

  # Package specification: either a bare package or an attrset with options.
  # Forms:
  #   - Bare package: pkgs.foobar (coerced to { value = pkgs.foobar; })
  #   - { value = pkgs.foobar; } -> realpath(lib.getExe value)
  #   - { value = pkgs.foobar; wrapped = true; } -> toWrapped(realpath(lib.getExe value))
  #   - { value = pkgs.foobar; path = "/bin/foo"; } -> "${lib.getBin value}${path}"
  #   - { regexp = "foo-[0-9]+"; path = "/bin/foo"; } -> regexp pattern
  packageType =
    let
      packageAttrSetType = lib.types.submodule {
        options = {
          value = lib.mkOption {
            type = lib.types.nullOr lib.types.package;
            default = null;
            description = "Package to resolve (mutually exclusive with regexp).";
          };
          wrapped = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Apply toWrapped transformation (requires value, incompatible with path).";
          };
          path = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Explicit path within package (requires value, incompatible with wrapped).";
          };
          regexp = lib.mkOption {
            type = lib.types.nullOr regexpStrType;
            default = null;
            description = "Package name regexp (mutually exclusive with value, requires path).";
          };
          scope = lib.mkOption {
            type = lib.types.nullOr packageScopeType;
            default = null;
            description = "Override defaultPackageScope for this rule.";
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
    };

    port = {
      type = "simple";
      operand = "dest.port";
      valueType = lib.types.int;
      regexpType = regexpStrType;
    };
    dstPort = {
      type = "simple";
      operand = "dest.port";
      valueType = lib.types.int;
      regexpType = regexpStrType;
    };
    srcPort = {
      type = "simple";
      operand = "source.port";
      valueType = lib.types.int;
      regexpType = regexpStrType;
    };

    ports = {
      type = "regexp";
      operand = "dest.port";
      valueType = lib.types.listOf lib.types.int;
      inherit listToRegexp;
    };
    dstPorts = {
      type = "regexp";
      operand = "dest.port";
      valueType = lib.types.listOf lib.types.int;
      inherit listToRegexp;
    };
    srcPorts = {
      type = "regexp";
      operand = "source.port";
      valueType = lib.types.listOf lib.types.int;
      inherit listToRegexp;
    };

    userName = {
      type = "simple";
      operand = "user.name";
    };
    user = {
      type = "simple";
      operand = "user.name";
    };
    userId = {
      type = "simple";
      operand = "user.id";
      valueType = lib.types.int;
    };

    ip = {
      type = "simple";
      operand = "dest.ip";
      regexpType = regexpStrType;
    };
    dstIp = {
      type = "simple";
      operand = "dest.ip";
      regexpType = regexpStrType;
    };
    srcIp = {
      type = "simple";
      operand = "source.ip";
      regexpType = regexpStrType;
    };

    network = {
      type = "simple";
      operand = "dest.network";
      regexpType = regexpStrType;
    };
    dstNetwork = {
      type = "simple";
      operand = "dest.network";
      regexpType = regexpStrType;
    };
    srcNetwork = {
      type = "simple";
      operand = "source.network";
      regexpType = regexpStrType;
    };

    proto = {
      type = "simple";
      operand = "protocol";
    };

    processPath = {
      type = "simple";
      operand = "process.path";
      regexpType = regexpStrType;
    };
    processCommand = {
      type = "simple";
      operand = "process.command";
      regexpType = regexpStrType;
    };

    iface = {
      type = "simple";
      operand = "iface.out";
    };
    ifaceIn = {
      type = "simple";
      operand = "iface.in";
    };
    ifaceOut = {
      type = "simple";
      operand = "iface.out";
    };

    ips = {
      type = "lists";
      operand = "lists.ips";
      valueType = lib.types.listOf lib.types.str;
      fileName = "ips.list";
      format = values: lib.concatStringsSep "\n" values;
    };

    nets = {
      type = "lists";
      operand = "lists.nets";
      valueType = lib.types.listOf lib.types.str;
      fileName = "nets.list";
      format = values: lib.concatStringsSep "\n" values;
    };

    domains = domainsSpec;
    hosts = domainsSpec;
  };

  regexpSubmoduleType =
    innerType:
    lib.types.submodule {
      options = {
        regexp = lib.mkOption {
          type = innerType;
          description = ".regexp value must be a string";
        };
      };
    };

  # Typed option attrs for a single rule fragment, derived from `conditionMap`
  # so the set of condition keys and their Nix value types live in exactly one
  # place. A spec without `valueType` defaults to a string; numeric conditions
  # declare `valueType = lib.types.int`. Conditions with `regexpType` support
  # `{ regexp = "..."; }` syntax.
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
    lib.mkOption {
      type = optionType;
      default = null;
      description = "OpenSnitch '${spec.operand}' (${spec.type}) condition.";
    }
  ) conditionMap;

  # Map array-expansion fields to their condition key and rule-name suffix.
  arrayExpansionMap = {
    users = {
      conditionKey = "user";
      suffix = "user";
    };
    userNames = {
      conditionKey = "userName";
      suffix = "user";
    };
    userIds = {
      conditionKey = "userId";
      suffix = "userId";
    };
  };

  arrayOptions = lib.mapAttrs (
    _fieldName: spec:
    let
      valueType = conditionMap.${spec.conditionKey}.valueType or lib.types.str;
    in
    lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf valueType);
      default = null;
      description = "Expand one rule per element into separate OpenSnitch rules.";
    }
  ) arrayExpansionMap;

  packageOption = lib.mkOption {
    type = lib.types.nullOr packageType;
    default = null;
    description = "Resolve a Nix package to a process condition.";
  };

  conditionsTypeWithArrays = lib.types.submodule {
    options = conditionsOptions // arrayOptions // { package = packageOption; };
  };

  # Typed schema for one rule entry: either a bare fragment, or wrapped in
  # `allow` / `deny` (each a fragment), with the default action applied when
  # neither wrapper is present.
  ruleType = lib.types.submodule {
    options = {
      allow = lib.mkOption {
        type = lib.types.nullOr conditionsTypeWithArrays;
        default = null;
        description = "Wrap a fragment with the 'allow' action.";
      };
      deny = lib.mkOption {
        type = lib.types.nullOr conditionsTypeWithArrays;
        default = null;
        description = "Wrap a fragment with the 'deny' action.";
      };
    }
    // conditionsOptions
    // arrayOptions
    // {
      package = packageOption;
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
        type = if isRegexp then "regexp" else "simple";
        inherit (spec) operand;
        data = if isRegexp then "^" + (builtins.toString value) + "$" else builtins.toString value;
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
  mkRule = name: action: timestamp: frag: {
    inherit action;
    created = timestamp;
    updated = timestamp;
    name = "opensnix-${name}";
    enabled = true;
    duration = "always";
    operator = mkOperator frag;
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
      hasWrapped = pkg.wrapped or false;
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
          regexp = "/nix/store/[a-z0-9]{32}-${pkg.regexp}${pkg.path}";
        };
      };

  resolvePackageWildcard =
    name: frag: pkg:
    let
      hasPath = pkg.path or null != null;
      hasWrapped = pkg.wrapped or false;
      hasRegexp = pkg ? regexp && pkg.regexp != null;
      hasValue = pkg ? value && pkg.value != null;
      pattern =
        if hasRegexp then
          pkg.regexp
        else if hasValue then
          lib.escapeRegex pkg.value.name
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
          regexp = "/nix/store/[a-z0-9]{32}-${pattern}/.*";
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
  #   - { allow = <fragment> } -> action = "allow"
  #   - { deny  = <fragment> } -> action = "deny"
  mkRules =
    {
      defaultAction,
      defaultPackageScope,
      rules,
      timestamp,
    }:
    let
      # Resolve the actual condition fragment and action for an entry, handling
      # the `allow`/`deny` wrappers and the typed schema's null defaults.
      resolve =
        entry:
        let
          wrapped =
            if entry.allow != null && entry.deny != null then
              builtins.throw "opensnix: a rule cannot specify both 'allow' and 'deny'."
            else if entry.allow != null then
              {
                fragment = entry.allow;
                action = "allow";
              }
            else if entry.deny != null then
              {
                fragment = entry.deny;
                action = "deny";
              }
            else
              {
                fragment = removeAttrs entry [
                  "allow"
                  "deny"
                ];
                action = defaultAction;
              };
        in
        wrapped
        // {
          fragment = lib.filterAttrs (_: v: v != null) wrapped.fragment;
        };

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
        in
        if builtins.length listFieldNames > 0 then
          builtins.throw "opensnix: rule '${name}' has empty list for '${builtins.head listFieldNames}'."
        else if builtins.length arrayFieldNames > 1 then
          builtins.throw "opensnix: rule '${name}' specifies multiple array fields (${builtins.concatStringsSep ", " arrayFieldNames}); only one is allowed."
        else if arrayFieldNames == [ ] then
          [
            {
              inherit name fragment;
              inherit (r) action;
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
              inherit (r) action;
            }) values;

      expandedEntries = lib.concatLists (
        lib.mapAttrsToList (
          name: entry:
          let
            r = resolve entry;
            rWithPackage = r // {
              fragment = resolvePackage name r.fragment defaultPackageScope;
            };
          in
          expandArrays name rWithPackage
        ) rules
      );

      dups = lib.filterAttrs (_: vs: builtins.length vs > 1) (lib.groupBy (e: e.name) expandedEntries);
    in
    if !utils.isRfc3339UTC timestamp then
      builtins.throw "opensnix: timestamp '${timestamp}' is not a valid RFC3339 UTC date-time (expected YYYY-MM-DDTHH:MM:SSZ)."
    else if dups != { } then
      throw "opensnix: duplicate rule name '${builtins.head (lib.attrNames dups)}' generated; check for duplicate values in array fields or conflicting rule names."
    else
      builtins.listToAttrs (
        map (e: lib.nameValuePair e.name (mkRule e.name e.action timestamp e.fragment)) expandedEntries
      );
in
{
  inherit
    mkRules
    ruleType
    ;
}
