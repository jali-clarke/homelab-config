{ config, ... }:
let
  meta = config.homelab-config.meta;
in
{
  imports = [
    ../../modules/meta
  ];

  services.nfs.server = {
    enable = true;
    nproc = 4; # 4 threads
    hostName = meta.atlas.networkIP;

    exports = ''
      /mnt/storage 192.168.0.0/24(rw,crossmnt,no_subtree_check,no_root_squash)
    '';
  };

  # still need to do `sudo smbpasswd -a pi`
  services.samba = {
    enable = true;

    shares = {
      backup_drive = {
        path = "/mnt/storage/backup_drive";
        browseable = "no";
        "guest ok" = "no";
        "read only" = "no";
      };

      media_and_such = {
        path = "/mnt/storage/data_drive";
        browseable = "no";
        "guest ok" = "no";
        "read only" = "no";
      };
    };
  };
}
