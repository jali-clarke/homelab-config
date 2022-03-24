{ config, lib, ... }: {
  options.homelab-config.router.tables =
    let
      inherit (lib) mkOption types;
      portListType = types.either (types.enum [ "ALL" ]) (types.nonEmptyListOf types.port);
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      defaultIncomingVerdict = mkOption {
        type = types.enum ["accept" "drop"];
        default = "drop";
      };

      allowedIcmpInterfaces = mkOption {
        type = types.listOf types.nonEmptyStr;
        default = [ ];
      };

      allowedTcpInterfaces = mkOption {
        type = types.attrsOf portListType;
        default = { };
      };

      allowedUdpInterfaces = mkOption {
        type = types.attrsOf portListType;
        default = { };
      };

      masqueradeInterfaces = mkOption {
        type = types.attrsOf types.nonEmptyStr;
        default = { };
      };
    };

  config =
    let
      cfg = config.homelab-config.router.tables;

      ruleTab = "\n    ";
      commaSeparated = lib.concatStringsSep ", ";

      mkIcmpRule = allowedIcmpInterfaces:
        if allowedIcmpInterfaces == [ ]
        then "# iifname {<interfaces>} icmp type echo-request accept"
        else "iifname {${commaSeparated allowedIcmpInterfaces}} icmp type echo-request accept";

      mkL4Rule = protocol: interfaceName: allowedPorts:
        if allowedPorts == "ALL"
        then "iifname ${interfaceName} ${protocol} accept"
        else
          let
            portsString = commaSeparated (builtins.map builtins.toString allowedPorts);
          in
          "iifname ${interfaceName} ${protocol} dport {${portsString}} accept";

      mkL4Rules = protocol: allowedInterfaces:
        if allowedInterfaces == { }
        then "# ${mkL4Rule protocol "<interface>" ["<ports>"]}"
        else
          let
            ruleLines = builtins.attrValues (builtins.mapAttrs (mkL4Rule protocol) allowedInterfaces);
          in
          lib.concatStringsSep ruleTab ruleLines;

      mkOutgoingForwardRule = masqueradeInterface: sourceRange: "oifname ${masqueradeInterface} ip saddr ${sourceRange} accept";

      mkOutgoingForwardRules = masqueradeInterfaces:
        if masqueradeInterfaces == { }
        then "# ${mkOutgoingForwardRule "<interface>" "<source-range>"}"
        else
          let
            ruleLines = builtins.attrValues (builtins.mapAttrs mkOutgoingForwardRule masqueradeInterfaces);
          in
          lib.concatStringsSep ruleTab ruleLines;

      mkIncomingForwardRule = masqueradeInterface: "iifname ${masqueradeInterface} ct state {related, established} accept";

      mkIncomingForwardRules = masqueradeInterfaces:
        if masqueradeInterfaces == { }
        then "# ${mkIncomingForwardRule "<interface>"}"
        else
          let
            ruleLines = builtins.map mkIncomingForwardRule (builtins.attrNames masqueradeInterfaces);
          in
          lib.concatStringsSep ruleTab ruleLines;

      mkMasqueradeRule = masqueradeInterface: sourceRange: "oifname ${masqueradeInterface} ip saddr ${sourceRange} masquerade";

      mkMasqueradeRules = masqueradeInterfaces:
        if masqueradeInterfaces == { }
        then "# ${mkMasqueradeRule "<interface>" "<source-range>"}"
        else
          let
            ruleLines = builtins.attrValues (builtins.mapAttrs mkMasqueradeRule masqueradeInterfaces);
          in
          lib.concatStringsSep ruleTab ruleLines;
    in
    lib.mkIf cfg.enable {
      boot.kernel.sysctl = lib.mkIf (cfg.masqueradeInterfaces != { }) {
        "net.ipv4.ip_forward" = 1;
      };

      networking.nftables = {
        enable = true;
        ruleset = ''
          table ip6 main {
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

          table ip main {
            chain input {
              # drop all incoming traffic according to homelab-config.router.tables.defaultIncomingVerdict
              type filter hook input priority filter; policy ${cfg.defaultIncomingVerdict};

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
              # disable forwarding according to homelab-config.router.tables.defaultIncomingVerdict
              type filter hook forward priority filter; policy ${cfg.defaultIncomingVerdict};

              # allow outgoing for interfaces specified by homelab-config.router.tables.masqueradeInterfaces
              ${mkOutgoingForwardRules cfg.masqueradeInterfaces}

              # allow incoming for established connections for interfaces specified by homelab-config.router.tables.masqueradeInterfaces
              ${mkIncomingForwardRules cfg.masqueradeInterfaces}
            }

            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;

              # masquerade outgoing traffic for interfaces specified by homelab-config.router.tables.masqueradeInterfaces
              ${mkMasqueradeRules cfg.masqueradeInterfaces}
            }
          }
        '';
      };
    };
}
