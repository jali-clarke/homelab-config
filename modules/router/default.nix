{ config, pkgs, lib, options, ... }: {
  options.homelab-config.router =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      dhcpInterface = mkOption {
        type = types.str;
        default = "eth0";
      };

      dhcpMachines = options.services.dhcpd4.machines;

      dnsServer = mkOption {
        type = types.str;
      };
    };

  config =
    let
      cfg = config.homelab-config.router;
      networkPrefix = "192.168.0";
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !config.networking.dhcpcd.enable;
          message = "networking.dhcpcd.enable should be false if using config.homelab-config.router";
        }
        {
          assertion = !config.networking.useDHCP;
          message = "networking.useDHCP should be false if using config.homelab-config.router";
        }
        {
          assertion = !config.networking.interfaces.${cfg.dhcpInterface}.useDHCP;
          message = "networking.interfaces.<dhcpInterface>.useDHCP should be false if using config.homelab-config.router";
        }
      ];

      services.dhcpd4 = {
        enable = true;
        interfaces = [ cfg.dhcpInterface ];
        machines = cfg.dhcpMachines;
        extraConfig = ''
          option subnet-mask 255.255.255.0;
          option broadcast-address ${networkPrefix}.255;
          option routers ${networkPrefix}.1;
          option domain-name-servers ${cfg.dnsServer};
          option domain-name "jali-clarke.ca";
          subnet ${networkPrefix}.0 netmask 255.255.255.0 {
            range ${networkPrefix}.4 ${networkPrefix}.199;
          }
        '';
      };
    };
}
