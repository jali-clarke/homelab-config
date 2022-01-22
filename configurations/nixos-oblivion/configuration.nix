# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ciphertexts, ... }:
let
  secretFilePi = secretFilePath: {
    file = secretFilePath;
    owner = "pi";
  };
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  environment.systemPackages = [
    pkgs.nixos-generators
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "nixos-oblivion"; # Define your hostname.

  age.secrets = {
    id_nixos_oblivion = secretFilePi ciphertexts."id_nixos_oblivion.age";
    "id_nixos_oblivion.pub" = secretFilePi ciphertexts."id_nixos_oblivion.pub.age";
  };
}
