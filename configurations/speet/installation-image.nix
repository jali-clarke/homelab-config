{ config, pkgs, lib, ... }:
let
  installationBundle =
    import ./installation-bundle.nix {
      pkgs = pkgs;
    };
in
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix>
    ../common/users.nix
  ];

  networking.hostName = "speet-installation"; # Define your hostname.
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.

  services.openssh.enable = true;
  systemd.services.sshd.wantedBy = lib.mkOverride 40 ["multi-user.target"];

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  sdImage.compressImage = false;

  environment.systemPackages = [
    installationBundle
  ];
}
