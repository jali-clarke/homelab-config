{ config, pkgs, lib, ... }:
let
  nexusPort = 8080;
  piholePort = 8081;
  vaultPort = 8082;

  meta = config.homelab-config.meta;
in
{
  imports = [
    ./filesystem-exports.nix # still need to do `sudo smbpasswd -a pi`
    ./hardware-configuration.nix
  ];

  environment.systemPackages = [
    pkgs.rename
  ];

  homelab-config.zfs = {
    enable = true;
    hostId = "c083c64b";
    zfsARCSizeMaxGB = 8;

    sanoidOpts = {
      enable = true;
      dataset = "storage";
      autosnap = true;
    };

    syncoidOpts = {
      enable = true;
      source = "storage";
      target = "pi@${meta.weedle.networkIP}:backups/storage";
      sshKey = config.age.secrets.id_rsa_nixops.path;
      sshNoVerify = true; # should be ok i promise
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = meta.atlas.hostName; # Define your hostname.

  homelab-config.nginx-proxy = {
    enable = true;
    serviceMap = {
      "nexus.jali-clarke.ca" = nexusPort;
      "pihole.jali-clarke.ca" = piholePort;
      "vault.jali-clarke.ca" = vaultPort;
    };
  };

  homelab-config.nexus = {
    enable = true;
    nexusHome = {
      create = false;
      path = "/mnt/storage/atlas_services/nexus_data";
    };
    webInterface = {
      # 0.0.0.0 required for docker access (which is not proxied)
      ip = "0.0.0.0";
      port = nexusPort;
    };
  };

  homelab-config.vault = {
    enable = true;
    storagePath = "/mnt/storage/atlas_services/vault_data";
    webInterface = {
      ip = "127.0.0.1";
      port = vaultPort;
    };
  };

  homelab-config.pihole = {
    enable = true;
    piholeDataPath = "/mnt/storage/atlas_services/pihole";
    webInterface = {
      ip = "127.0.0.1";
      port = piholePort;
    };

    extraDnsmasqConfig =
      let
        mkHostRecord = hostMeta: "host-record=${hostMeta.hostNameWithDomain},${hostMeta.hostName},${hostMeta.networkIP}";
        mkCnameRecord = hostMeta: cnameHost: "cname=${cnameHost}.jali-clarke.ca,${hostMeta.hostNameWithDomain}";
      in
      ''
        # host records

        ${lib.concatMapStringsSep "\n" mkHostRecord (builtins.attrValues meta)}

        # cname records

        ${
          lib.concatMapStringsSep "\n" (mkCnameRecord meta.atlas) [
            "pihole"
            "nexus"
            "vault"
          ]
        }

        ${
          lib.concatMapStringsSep "\n" (mkCnameRecord meta.ingress) [
            "grafana"
            "markov"
            "markov-app"
            "torrents"
          ]
        }

        ${
          lib.concatMapStringsSep "\n" (mkCnameRecord meta.ingress-external) [
            "argo"
            "argocd"
            "argo-rollouts"
            "emby"
            "keycloak"

            "web-dev"
            "files-dev"
            "dev"

            "web-dev-staging"
            "files-dev-staging"
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
