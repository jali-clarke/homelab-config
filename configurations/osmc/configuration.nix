# inspired by https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4
{ config, lib, pkgs, ciphertexts, nixos-hardware-modules, ... }:
let
  meta = config.homelab-config.meta;

  secretFilePi = secretFilePath: {
    file = secretFilePath;
    owner = "pi";
  };
in
{
  imports = [
    nixos-hardware-modules.raspberry-pi-4
  ];

  nix.extraOptions = ''
    extra-platforms = armv7l-linux
  '';

  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # leave this disabled - it's incompatible with `boot.loader.generic-extlinux-compatible.enable = false`
  # boot.loader.raspberryPi = {
  #   enable = true;
  #   version = 4;
  #   firmwareConfig = ''
  #     dtparam=audio=on
  #   '';
  # };

  hardware.raspberry-pi."4" = {
    audio.enable = true;
    fkms-3d.enable = true;
  };

  # boot.initrd.availableKernelModules = [ "usbhid" "usb_storage" ];

  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
  # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
  # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
  boot.kernelParams = [ "cma=128M" ];

  # File systems configuration for using the installer's partition layout
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  # !!! Adding a swap file is optional, but strongly recommended!
  # swapDevices = [ { device = "/swapfile"; size = 3072; } ];

  networking.hostName = meta.osmc.hostName; # Define your hostname.

  powerManagement.cpuFreqGovernor = "ondemand";

  age.secrets = {
    id_osmc = secretFilePi ciphertexts."id_osmc.age";
    "id_osmc.pub" = secretFilePi ciphertexts."id_osmc.pub.age";
  };

  homelab-config.kodi = {
    enable = true;
    remoteControlPort = 8080;
  };

  system.stateVersion = "21.05"; # Did you read the comment?
}
