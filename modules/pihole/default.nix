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
      assertions = [
        {
          assertion = pkgs.system == "x86_64-linux";
          message = "homelab-config.modules.pihole is currently only supported on x86_64-linux";
        }
      ];

      virtualisation.oci-containers.containers.pihole =
        let
          imageName = "pihole/pihole";
          finalImageTag = "2022.05";

          pulledImage = pkgs.dockerTools.pullImage {
            inherit imageName finalImageTag;
            # warning - below is for the amd64 image.  too lazy to set this up for other archs
            imageDigest = "sha256:f56885979dcffeb902d2ca51828c92118199222ffb8f6644505e7881e11eeb85";
            sha256 = "sha256-AWexkM9bBFjxxfHt+gUA+8VMQGtnrZyeo7hxeyzqwyM=";
          };
        in
        {
          image = "${imageName}:${finalImageTag}";
          imageFile = pulledImage;

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
