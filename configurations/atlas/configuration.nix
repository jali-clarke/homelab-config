{config, pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix

    ../../common/common-config.nix
    ../../common/users
    ../../common/zfs-support.nix
  ];

  homelab-config.zfs-support = {
    zfsARCSizeMaxGB = 8;
    hostId = "c083c64b";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "atlas"; # Define your hostname.
}
