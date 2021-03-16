{pkgs, lib, ...}:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix>
    ../../modules/common-config.nix
    ../../modules/users
  ];

  networking.hostName = "pi-baker"; # Define your hostname.
  systemd.services.sshd.wantedBy = lib.mkOverride 40 ["multi-user.target"];
  sdImage.compressImage = false;
}
