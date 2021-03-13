# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }: {
  imports = [
    ../../common/users
    ../../common/system-packages.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  networking.hostName = "bootstrap-bill"; # Define your hostname.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  services.openssh.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  networking.useDHCP = true;

  users.mutableUsers = false;
  users.users.pi = {
    hashedPassword = passwordHashes.pi;
    isNormalUser = true;
    extraGroups = ["wheel"];
  };

  environment.systemPackages = [
    pkgs.nfs-utils
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
