# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{pkgs, ...}:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../common/common-config.nix
      ../../common/users
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  networking.hostName = "nixos-oblivion"; # Define your hostname.

  environment.systemPackages = [
    pkgs.nixos-generators
  ];
}
