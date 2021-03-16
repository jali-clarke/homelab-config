{config, pkgs, lib, ...}: {
  options.homelab-config.pihole-support =
    let
      inherit (lib) mkOption types;
    in
    {
      extraDnsmasqConfig = mkOption {
        type = types.lines;
        default = "";
      };

      ipv6Enabled = mkOption {
        type = types.bool;
        default = false;
      };

      webPortListenInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };

  config =
    let
      cfg = config.homelab-config.pihole-support;
      piholeLanConf = pkgs.writeText "02-lan.conf" cfg.extraDnsmasqConfig;
    in
    {
      virtualisation.oci-containers.containers.pihole = {
        image = "pihole/pihole:4.2.2-1";

        environment = {
          IPv6 = if cfg.ipv6Enabled then "True" else "False";
        };

        ports = lib.optionals (cfg.webPortListenInterface != null) ["${cfg.webPortListenInterface}:80/tcp"] ++ [
          "53:53/tcp"
          "53:53/udp"
        ];

        volumes = [
          "/mnt/stroage/recordsize-128K/pihole/config:/etc/pihole"
          "/mnt/stroage/recordsize-128K/pihole/dnsmasq:/etc/dnsmasq.d"
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
