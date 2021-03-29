{ config, pkgs, lib, ... }:
let
  nexusPort = 8080;
  piholePort = 8081;

  meta = config.homelab-config.meta;
in
{
  imports = [
    ./filesystem-exports.nix # still need to do `sudo smbpasswd -a pi`
    ./hardware-configuration.nix

    ../../modules/common-config
    ../../modules/meta
    ../../modules/nexus
    ../../modules/nginx-proxy
    ../../modules/pihole
    ../../modules/users
    ../../modules/zfs
  ];

  environment.systemPackages = [
    (import ../../lib/load-ssh-key.nix { inherit pkgs; })
  ];

  homelab-config.zfs = {
    hostId = "c083c64b";
    zfsARCSizeMaxGB = 8;

    sanoidOpts = {
      dataset = "storage";
      autosnap = true;
    };

    syncoidOpts = {
      source = "storage";
      target = "pi@${meta.weedle.networkIP}:backups/storage";
      sshKey = "/home/pi/.ssh/id_rsa_nixops";
      sshNoVerify = true; # should be ok i promise
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = meta.atlas.hostName; # Define your hostname.

  homelab-config.nginx-proxy.serviceMap = {
    "nexus.lan" = nexusPort;
    "pihole.lan" = piholePort;
  };

  homelab-config.nexus = {
    enable = true;
    nexusDataPath = "/mnt/storage/recordsize-1M/atlas_services/nexus_data";
    dockerInterface.port = 5000;
    webInterface = {
      ip = "127.0.0.1";
      port = nexusPort;
    };
  };

  homelab-config.pihole = {
    piholeDataPath = "/mnt/storage/recordsize-128K/atlas_services/pihole";

    webInterface = {
      ip = "127.0.0.1";
      port = piholePort;
    };

    extraDnsmasqConfig =
      let
        mkHostRecord = hostMeta: "host-record=${hostMeta.hostNameWithDomain},${hostMeta.hostName},${hostMeta.networkIP}";
        mkCnameRecord = hostMeta: cnameHost: "cname=${cnameHost}.lan,${cnameHost},${hostMeta.hostNameWithDomain}";
      in
      ''
        # host records

        ${lib.concatMapStringsSep "\n" mkHostRecord (builtins.attrValues meta)}

        # cname records

        ${
          lib.concatMapStringsSep "\n" (mkCnameRecord meta.atlas) [
            "pihole"
            "nexus"
          ]
        }

        ${
          lib.concatMapStringsSep "\n" (mkCnameRecord meta.ingress) [
            "emby"
            "grafana"
            "markov"
            "markov-app"
            "torrents"

            "web.dev"
            "files.dev"
            "dev"

            "web.dev-staging"
            "files.dev-staging"
            "dev-staging"
          ]
        }
      '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
