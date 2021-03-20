{ config, pkgs, ... }:
let
  meta = config.homelab-config.meta;
in
{
  imports = [
    ../../modules/common-config
    ../../modules/kubernetes
    ../../modules/meta
    ../../modules/users
  ];

  environment.systemPackages = [
    (import ../../lib/load-ssh-key.nix { inherit pkgs; })
  ];

  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = pkgs.linuxPackages;

  # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
  # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
  # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
  boot.kernelParams = [ "cma=32M" ];

  # File systems configuration for using the installer's partition layout
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  # !!! Adding a swap file is optional, but strongly recommended!
  # swapDevices = [ { device = "/swapfile"; size = 3072; } ]; # does not play nice with k8s

  networking.hostName = meta.speet.hostName; # Define your hostname.
  homelab-config.k8s = {
    masterIP = meta.weedle.networkIP;
    masterHostname = meta.weedle.hostName;
  };

  # systemd.services.etcd.environment.ETCD_UNSUPPORTED_ARCH = "arm64"; # only if the pi is the k8s master
  }
