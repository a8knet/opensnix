{ lib }:
let
  # Map a simple-rule condition field to its OpenSnitch operator spec.
  # The `data` is filled in by mkOperator from the user-supplied value.
  conditionMap = {
    host = {
      type = "simple";
      operand = "dest.host";
    };
    hostRE = {
      type = "regexp";
      operand = "dest.host";
    };

    port = {
      type = "simple";
      operand = "dest.port";
      valueType = lib.types.int;
    };
    dstPort = {
      type = "simple";
      operand = "dest.port";
      valueType = lib.types.int;
    };
    srcPort = {
      type = "simple";
      operand = "source.port";
      valueType = lib.types.int;
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
    };
    dstIp = {
      type = "simple";
      operand = "dest.ip";
    };
    srcIp = {
      type = "simple";
      operand = "source.ip";
    };

    network = {
      type = "simple";
      operand = "dest.network";
    };
    dstNetwork = {
      type = "simple";
      operand = "dest.network";
    };
    srcNetwork = {
      type = "simple";
      operand = "source.network";
    };

    ipRE = {
      type = "regexp";
      operand = "dest.ip";
    };
    dstIpRE = {
      type = "regexp";
      operand = "dest.ip";
    };
    srcIpRE = {
      type = "regexp";
      operand = "source.ip";
    };
    networkRE = {
      type = "regexp";
      operand = "dest.network";
    };
    dstNetworkRE = {
      type = "regexp";
      operand = "dest.network";
    };
    srcNetworkRE = {
      type = "regexp";
      operand = "source.network";
    };

    proto = {
      type = "simple";
      operand = "protocol";
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
  };

  # Typed option attrs for a single rule fragment, derived from `conditionMap`
  # so the set of condition keys and their Nix value types live in exactly one
  # place. A spec without `valueType` defaults to a string; numeric conditions
  # declare `valueType = lib.types.int`.
  conditionsOptions = lib.mapAttrs (
    _: spec:
    lib.mkOption {
      type = lib.types.nullOr (spec.valueType or lib.types.str);
      default = null;
      description = "OpenSnitch '${spec.operand}' (${spec.type}) condition.";
    }
  ) conditionMap;

  conditionsType = lib.types.submodule { options = conditionsOptions; };

  # Typed schema for one rule entry: either a bare fragment, or wrapped in
  # `allow` / `deny` (each a fragment), with the default action applied when
  # neither wrapper is present.
  ruleType = lib.types.submodule {
    options = {
      allow = lib.mkOption {
        type = lib.types.nullOr conditionsType;
        default = null;
        description = "Wrap a fragment with the 'allow' action.";
      };
      deny = lib.mkOption {
        type = lib.types.nullOr conditionsType;
        default = null;
        description = "Wrap a fragment with the 'deny' action.";
      };
    }
    // conditionsOptions;
  };

  # Build a single child operator for one condition key.
  mkChild =
    frag: key:
    let
      spec = conditionMap.${key};
      value = frag.${key};
    in
    {
      inherit (spec) type operand;
      data =
        if spec.type == "regexp" then "$" + (builtins.toString value) + "^" else builtins.toString value;
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
in
{
  inherit
    mkRule
    mkOperator
    mkChild
    ruleType
    conditionsType
    ;

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
      rules,
      timestamp,
    }:
    let
      # Resolve the actual condition fragment and action for an entry, handling
      # the `allow`/`deny` wrappers and the typed schema's null defaults.
      resolve =
        entry:
        let
          hasAllow = entry ? allow && entry.allow != null;
          hasDeny = entry ? deny && entry.deny != null;
          wrapped =
            if hasAllow && hasDeny then
              builtins.throw "opensnix: a rule cannot specify both 'allow' and 'deny'."
            else if hasAllow then
              {
                fragment = entry.allow;
                action = "allow";
              }
            else if hasDeny then
              {
                fragment = entry.deny;
                action = "deny";
              }
            else
              {
                fragment = lib.filterAttrs (k: _: k != "allow" && k != "deny") entry;
                action = defaultAction;
              };
        in
        wrapped
        // {
          fragment = lib.filterAttrs (_: v: v != null) wrapped.fragment;
        };
    in
    lib.mapAttrs (
      name: entry:
      let
        r = resolve entry;
      in
      mkRule name r.action timestamp r.fragment
    ) rules;
}
