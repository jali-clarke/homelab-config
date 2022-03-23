{ config, lib, ... }: {
  options.homelab-config.router.tables =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      allowedIcmpInterfaces = mkOption {
        type = types.listOf types.nonEmptyStr;
        default = [ ];
      };

      allowedTcpInterfaces = mkOption {
        type = types.attrsOf (types.nonEmptyListOf types.port);
        default = { };
      };

      allowedUdpInterfaces = mkOption {
        type = types.attrsOf (types.nonEmptyListOf types.port);
        default = { };
      };
    };

  config =
    let
      cfg = config.homelab-config.router.tables;
      commaSeparated = lib.concatStringsSep ", ";

      mkIcmpRule = allowedIcmpInterfaces:
        if allowedIcmpInterfaces == [ ]
        then "# iifname {<interfaces>} icmp type echo-request accept"
        else "iifname {${commaSeparated allowedIcmpInterfaces}} icmp type echo-request accept";

      mkL4Rule = protocol: interfaceName: allowedPorts:
        let
          portsString = commaSeparated (builtins.map builtins.toString allowedPorts);
        in
        "iifname ${interfaceName} ${protocol} dport {${portsString}} accept";

      mkL4Rules = protocol: allowedInterfaces:
        if allowedInterfaces == { }
        then "# iifname <interface> ${protocol} dport {<ports>} accept"
        else
          let
            ruleLines = builtins.attrValues (builtins.mapAttrs (mkL4Rule protocol) allowedInterfaces);
          in
          lib.concatStringsSep "\n    " ruleLines;
    in
    lib.mkIf cfg.enable {
      networking.nftables = {
        enable = true;
        ruleset = ''
          table ip6 filter {
            chain input {
              # drop all incoming ipv6 traffic by default
              type filter hook input priority filter; policy drop;

              # accept any packets coming from established connections that originated from this machine
              ct state {established, related} accept

              # accept anything coming from localhost
              iifname lo accept
            }

            chain output {
              # allow all outgoing connections
              type filter hook output priority filter; policy accept;
            }

            chain forward {
              # disable forwarding
              type filter hook forward priority filter; policy drop;
            }
          }

          table ip filter {
            chain input {
              # drop all incoming traffic by default
              type filter hook input priority filter; policy drop;

              # accept any packets coming from established connections that originated from this machine
              ct state {established, related} accept

              # accept anything coming from localhost
              iifname lo accept

              # accept pings on all interfaces specified by homelab-config.router.tables.allowedIcmpInterfaces
              ${mkIcmpRule cfg.allowedIcmpInterfaces}

              # accept tcp on all interfaces specified by homelab-config.router.tables.allowedTcpInterfaces
              ${mkL4Rules "tcp" cfg.allowedTcpInterfaces}

              # accept udp on all interfaces specified by homelab-config.router.tables.allowedUdpInterfaces
              ${mkL4Rules "udp" cfg.allowedUdpInterfaces}
            }

            chain output {
              # allow all outgoing connections
              type filter hook output priority filter; policy accept;
            }
            
            chain forward {
              # disable forwarding
              type filter hook forward priority filter; policy drop;
            }
          }
        '';
      };
    };
}
