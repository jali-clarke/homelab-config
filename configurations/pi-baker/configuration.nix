{ lib, ... }:
{
  networking.hostName = "pi-baker"; # Define your hostname.
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];
  sdImage.compressImage = false;
}
