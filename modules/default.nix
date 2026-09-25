{
  config,
  lib,
  self,
}:
let
  opensnixLib = self.lib;
  cfg = config.opensnix;

  rendered = opensnixLib.mkRules {
    inherit (cfg) defaultAction rules timestamp;
  };
in
{
  options.opensnix = {
    enable = lib.mkEnableOption "opensnix declarative OpenSnitch rules";

    defaultAction = lib.mkOption {
      type = lib.types.enum [
        "allow"
        "deny"
      ];
      default = "allow";
      description = ''
        Action applied to rules that do not specify an explicit
        `allow` or `deny` subkey.
      '';
    };

    timestamp = lib.mkOption {
      type = lib.types.str;
      default = self.lastModifiedDate;
      description = ''
        Timestamp used for the `created`/`updated` fields of every rule.
        Defaults to the flake's `self.lastModifiedDate`.
      '';
    };

    rules = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        OpenSnitch rules. Each attribute name is the rule identifier; its
        value is either a single-condition fragment or an attrset with an
        `allow` or `deny` subkey wrapping the fragment.

        A fragment is an attrset with exactly one of the following condition
        keys (the value is emitted as the operator `data`, always as a
        string):

          host            -> simple  on dest.host
          hostRE          -> regexp  on dest.host        (wrapped as $...^)
          port / dstPort  -> simple  on dest.port
          srcPort         -> simple  on source.port
          user / userName -> simple  on user.name
          userId          -> simple  on user.id
          ip / dstIp      -> simple  on dest.ip
          srcIp           -> simple  on source.ip
          network / dstNetwork -> simple on dest.network (CIDR)
          srcNetwork      -> simple  on source.network
          ipRE / dstIpRE  -> regexp  on dest.ip          (wrapped as $...^)
          srcIpRE         -> regexp  on source.ip        (wrapped as $...^)
          networkRE / dstNetworkRE -> regexp on dest.network (wrapped $...^)
          srcNetworkRE    -> regexp  on source.network   (wrapped as $...^)
          proto           -> simple  on protocol
          iface           -> simple  on iface.out
          ifaceIn         -> simple  on iface.in
          ifaceOut        -> simple  on iface.out
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.opensnitch.rules = rendered;
  };
}
