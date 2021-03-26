# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }: {
  imports = [
    ../../modules/common-config
    ../../modules/users
    ../../modules/zfs
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "bootstrap-bill"; # Define your hostname.

  environment.systemPackages = [
    pkgs.nfs-utils
  ];

  homelab-config.zfs = {
    doAutoScrub = false;
    doAutoSMART = false;
  };
}
