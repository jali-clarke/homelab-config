{ config, pkgs, lib, ... }:
let
  dockerPort = 5000;
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

  age.secrets."cloudflare_creds.env".file = ../../secrets/cloudflare_creds.env.age;

  homelab-config.acme-cloudflare = {
    enable = true;
    readableByGroup = config.services.nginx.group;
    reloadServices = [ "nginx.service" ];
    credentialsFile = config.age.secrets."cloudflare_creds.env".path;
    domains = [
      "docker.jali-clarke.ca"
      "nexus.jali-clarke.ca"
      "pihole.jali-clarke.ca"
      "vault.jali-clarke.ca"
    ];
  };

  homelab-config.nginx-proxy = {
    enable = true;

    httpsServiceMap =
      let
        withCertPaths = host: info: info // {
          certPath = "/var/lib/acme/${host}/cert.pem";
          privateKeyPath = "/var/lib/acme/${host}/key.pem";
        };
      in builtins.mapAttrs withCertPaths {
        "docker.jali-clarke.ca" = {
          port = dockerPort;
          extraConfig = ''
            client_max_body_size 0;
            proxy_request_buffering off;
          '';
        };

        "nexus.jali-clarke.ca" = {
          port = nexusPort;
          extraConfig = ''
            proxy_set_header X-Forwarded-Proto "https";
          '';
        };

        "pihole.jali-clarke.ca" = {
          port = piholePort;
        };

        "vault.jali-clarke.ca" = {
          port = vaultPort;
        };
      };
  };

  homelab-config.nexus = {
    enable = true;
    nexusHome = {
      create = false;
      path = "/mnt/storage/atlas_services/nexus_data";
    };
    webInterface = {
      ip = "127.0.0.1";
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
            "docker"
            "nexus"
            "pihole"
            "vault"
          ]
        }

        ${
          lib.concatMapStringsSep "\n" (mkCnameRecord meta.ingress) [
            "argo"
            "grafana"
            "keycloak"
            "markov"
            "markov-app"
          ]
        }

        ${
          lib.concatMapStringsSep "\n" (mkCnameRecord meta.ingress-external) [
            "argocd"
            "argo-rollouts"
            "emby"

            "dev"
            "files.dev"
            "web.dev"

            "staging.dev"
            "files.staging.dev"
            "web.staging.dev"

            "torrents"
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
