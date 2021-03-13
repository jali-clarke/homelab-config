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

  networking.hostName = "atlas"; # Define your hostname.
}
