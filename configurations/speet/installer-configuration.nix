{pkgs, lib, ...}:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix>
    ../../common/common-config.nix
    ../../common/users
  ];

  networking.hostName = "speet"; # Define your hostname.
  systemd.services.sshd.wantedBy = lib.mkOverride 40 ["multi-user.target"];
  sdImage.compressImage = false;
}
