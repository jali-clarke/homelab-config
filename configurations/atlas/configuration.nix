{config, pkgs, ...}: {
  imports = [
    ./filesystem-exports.nix
    ./hardware-configuration.nix

    ../../modules/common-config
    ../../modules/nexus
    ../../modules/pihole
    ../../modules/users
    ../../modules/zfs
  ];

  homelab-config.zfs = {
    zfsARCSizeMaxGB = 8;
    hostId = "c083c64b";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "atlas"; # Define your hostname.

  homelab-config.nexus = {
    dockerInterface.port = 5000;
    webInterface.port = 8081;
  };

  homelab-config.pihole = {
    webInterface.port = 8080;

    extraDnsmasqConfig = ''
      # bare-metal infra

      host-record=speet.lan,speet,192.168.0.101
      host-record=weedle.lan,weedle,192.168.0.102
      host-record=atlas.lan,atlas,192.168.0.103
      host-record=osmc.lan,osmc,192.168.0.104
      host-record=scribe.lan,scribe,192.168.0.105

      # bare-metal services

      cname=pihole.lan,pihole,atlas.lan
      cname=nexus.lan,nexus,atlas.lan

      # k8s ingress

      host-record=ingress.lan,ingress,192.168.0.200

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
