{ config, pkgs, lib, options, ... }: {
  options.homelab-config.router.dhcp =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      listenInterface = mkOption {
        type = types.str;
        default = "eth0";
      };

      subnet = mkOption {
        type = types.str;
        default = "192.168.0.0";
      };

      defaultGateway = mkOption {
        type = types.str;
      };

      dnsServer = mkOption {
        type = types.str;
      };

      rangeStart = mkOption {
        type = types.str;
      };

      rangeEnd = mkOption {
        type = types.str;
      };

      staticLeases = options.services.dhcpd4.machines;
    };

  config =
    let
      cfg = config.homelab-config.router.dhcp;
      broadcastAddress = builtins.concatStringsSep "." (
        lib.take 3 (builtins.filter builtins.isString (builtins.split "\\." cfg.subnet)) ++ ["255"]
      );
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !config.networking.dhcpcd.enable;
          message = "networking.dhcpcd.enable should be false if using config.homelab-config.router.dhcp";
        }
        {
          assertion = !config.networking.useDHCP;
          message = "networking.useDHCP should be false if using config.homelab-config.router.dhcp";
        }
        {
          assertion = !config.networking.interfaces.${cfg.listenInterface}.useDHCP;
          message = "networking.interfaces.<listenInterface>.useDHCP should be false if using config.homelab-config.router.dhcp";
        }
      ];

      services.dhcpd4 = {
        enable = true;
        interfaces = [ cfg.listenInterface ];
        machines = cfg.staticLeases;
        extraConfig = ''
          ddns-updates off;

          option subnet-mask 255.255.255.0;
          option broadcast-address ${broadcastAddress};
          option routers ${cfg.defaultGateway};
          option domain-name-servers ${cfg.dnsServer};
          option domain-name "jali-clarke.ca";
          subnet ${cfg.subnet} netmask 255.255.255.0 {
            range ${cfg.rangeStart} ${cfg.rangeEnd};
          }
        '';
      };
    };
}
