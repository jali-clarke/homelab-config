{ config, pkgs, ... }:
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
    dockerInterface.port = 5000;
    webInterface = {
      ip = "127.0.0.1";
      port = nexusPort;
    };
  };

  homelab-config.pihole = {
    webInterface = {
      ip = "127.0.0.1";
      port = piholePort;
    };

    extraDnsmasqConfig =
      let
        mkHostRecord = hostName:
          let
            hostMeta = meta.${hostName};
          in
          "host-record=${hostMeta.hostNameWithDomain},${hostMeta.hostName},${hostMeta.networkIP}";
      in
      ''
        # bare-metal infra

        ${mkHostRecord "speet"}
        ${mkHostRecord "weedle"}
        ${mkHostRecord "atlas"}
        ${mkHostRecord "osmc"}
        ${mkHostRecord "scribe"}

        # bare-metal services

        cname=pihole.lan,pihole,${meta.atlas.hostNameWithDomain}
        cname=nexus.lan,nexus,${meta.atlas.hostNameWithDomain}

        # k8s ingress

        ${mkHostRecord "ingress"}

        cname=emby.lan,emby,ingress.lan
        cname=web.dev.lan,files.dev.lan,dev.lan,dev,ingress.lan
        cname=web.dev-staging.lan,files.dev-staging.lan,dev-staging.lan,dev-staging,ingress.lan
        cname=grafana.lan,grafana,ingress.lan
        cname=markov.lan,markov,ingress.lan
        cname=markov-app.lan,markov-app,ingress.lan
        cname=torrents.lan,torrents,ingress.lan
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
