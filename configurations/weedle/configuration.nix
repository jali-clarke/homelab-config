{config, pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix

    ../../common/common-config.nix
    ../../common/users
    ../../common/zfs-support.nix
  ];

  homelab-config.zfs-support = {
    zfsARCSizeMaxGB = 2;
    hostId = "74004318";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "weedle"; # Define your hostname.

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
