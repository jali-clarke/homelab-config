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
    ./opengl-fixes.nix
  ];

  nix.extraOptions = ''
    extra-platforms = armv7l-linux
  '';

  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;

    # can't set this yet because of a bad assert @
    # https://github.com/NixOS/nixpkgs/blob/a13d59408da1108fc6c9ffe4750ab7a33c581d24/nixos/modules/hardware/opengl.nix#L129
    # so we hack around this in ./opengl-fixes.nix
    #
    # driSupport32Bit = true;

    # hidden option - required since we build kodi from
    # 32-bit arm packages
    # ref: https://discourse.nixos.org/t/how-do-you-replace-mesa-without-recompiling-everything/13142
    package = pkgs.mesa.drivers;
    package32 = pkgs.pkgsArm32.mesa.drivers;
  };

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

  networking.hostName = meta.osmc.hostName; # Define your hostname.

  powerManagement.cpuFreqGovernor = "ondemand";

  age.secrets = {
    id_osmc = secretFilePi ciphertexts."id_osmc.age";
    "id_osmc.pub" = secretFilePi ciphertexts."id_osmc.pub.age";
  };

  environment.systemPackages = [ pkgs.pkgsArm32.gdb ];

  homelab-config.kodi = {
    enable = true;
    remoteControlPort = 8080;
    package = pkgs.pkgsArm32.callPackage ../../modules/kodi/kodi.nix { };
  };

  system.stateVersion = "21.05"; # Did you read the comment?
}
