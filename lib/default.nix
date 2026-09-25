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
    };
    dstPort = {
      type = "simple";
      operand = "dest.port";
    };
    srcPort = {
      type = "simple";
      operand = "source.port";
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

  # Build the operator for a single-condition rule fragment.
  mkOperator =
    frag:
    let
      names = builtins.attrNames frag;
      supported = lib.concatStringsSep ", " (builtins.attrNames conditionMap);
    in
    if builtins.length names != 1 then
      builtins.throw ''
        opensnix: a rule currently supports exactly one condition, got ${toString (builtins.length names)} (${toString names}).
        Combining multiple conditions via list operators is not implemented yet.''
    else
      let
        key = builtins.head names;
        spec = conditionMap.${key} or null;
      in
      if spec == null then
        builtins.throw ''
          opensnix: unknown rule condition '${key}'.
          Supported conditions: ${supported}.''
      else
        spec
        // {
          data =
            if spec.type == "regexp" then
              "$" + (builtins.toString frag.${key}) + "^"
            else
              builtins.toString frag.${key};
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
  inherit mkRule mkOperator;

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
    lib.mapAttrs (
      name: entry:
      if entry ? allow then
        mkRule name "allow" timestamp entry.allow
      else if entry ? deny then
        mkRule name "deny" timestamp entry.deny
      else
        mkRule name defaultAction timestamp entry
    ) rules;
}
