{ config, pkgs, ciphertexts, ... }:
let
  meta = config.homelab-config.meta;

  secretFilePi = secretFilePath: {
    file = secretFilePath;
    owner = "pi";
  };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  homelab-config.zfs = {
    enable = true;
    zfsARCSizeMaxGB = 2;
    hostId = "74004318";

    sanoidOpts = {
      enable = true;
      dataset = "backups/storage";
      autosnap = false;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = meta.weedle.hostName; # Define your hostname.

  age.secrets = {
    "id_atlas.pub".file = ciphertexts."id_atlas.pub.age";
    id_weedle = secretFilePi ciphertexts."id_weedle.age";
    "id_weedle.pub" = secretFilePi ciphertexts."id_weedle.pub.age";
  };

  homelab-config.users = {
    authorizedKeyPaths = [ config.age.secrets."id_atlas.pub".path ];
    authorizedKeysExtraActivationDeps = [ "agenix" ];
  };

  homelab-config.k8s = {
    enable = true;
    isMaster = true;
    masterIP = meta.weedle.networkIP;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
