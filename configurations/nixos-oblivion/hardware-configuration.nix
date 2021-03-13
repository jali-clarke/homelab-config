# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/d4cdc2e4-dd35-4e85-8715-1836a2c912d3";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/7C54-142F";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/79ab9b28-91b2-4243-878b-15a6e6b5c7f4"; }
    ];

  virtualisation.hypervGuest.enable = true;
}