{ config, pkgs, lib, ... }: {
  options.homelab-config.pihole =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      extraDnsmasqConfig = mkOption {
        type = types.lines;
        default = "";
      };

      ipv6Enabled = mkOption {
        type = types.bool;
        default = false;
      };

      piholeDataPath = mkOption {
        type = types.path;
      };

      webInterface = {
        ip = mkOption {
          type = types.str;
          default = "0.0.0.0";
        };

        port = mkOption {
          type = types.port;
          default = 80;
        };
      };
    };

  config =
    let
      cfg = config.homelab-config.pihole;
      piholeLanConf = pkgs.writeText "02-lan.conf" cfg.extraDnsmasqConfig;
    in
    lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers.pihole = {
        image = "pihole/pihole:v5.7";

        environment = {
          IPv6 = if cfg.ipv6Enabled then "True" else "False";
        };

        ports = [
          "${cfg.webInterface.ip}:${toString cfg.webInterface.port}:80/tcp"
          "53:53/tcp"
          "53:53/udp"
        ];

        volumes = [
          "${cfg.piholeDataPath}/config:/etc/pihole"
          "${cfg.piholeDataPath}/dnsmasq:/etc/dnsmasq.d"
          "${piholeLanConf}:/etc/dnsmasq.d/02-lan.conf:ro"
        ];

        extraOptions = [
          "--hostname=pihole"
          "--dns=127.0.0.1"

          "--cpus=0.1"
          "--memory=128m"
        ];
      };
    };
}
