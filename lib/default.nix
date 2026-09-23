{ lib }:
let
  # Build a single OpenSnitch rule for the given name.
  # `rule` is the user-provided fragment (operator, precedence, ...); the
  # internally managed fields are always set here and override whatever the
  # user supplied (passthrough of other fields is intentional for now).
  mkRule =
    name: action: timestamp: rule:
    rule
    // {
      inherit action;
      created = timestamp;
      updated = timestamp;
      name = "opensnix-${name}";
      enabled = true;
      duration = "always";
    };
in
{
  inherit mkRule;

  # Turn the opensnix.rules attrset into an attrset of full OpenSnitch rules,
  # shaped exactly like `services.opensnitch.rules` (attrsOf freeform).
  #
  # Each entry may be:
  #   - a bare rule fragment  -> action taken from defaultAction
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
