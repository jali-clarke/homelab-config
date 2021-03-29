{ config, ... }:
let
  meta = config.homelab-config.meta;
in
{
  imports = [
    ../../modules/meta
  ];

  services.nfs.server = {
    enable = false; # to revert
    nproc = 4; # 4 threads
    hostName = meta.atlas.networkIP;

    exports = ''
      /mnt/storage/recordsize-128K 192.168.0.0/24(rw,no_subtree_check,no_root_squash)
      /mnt/storage/recordsize-1M 192.168.0.0/24(rw,no_subtree_check,no_root_squash)
    '';
  };

  # still need to do `sudo smbpasswd -a pi`
  services.samba = {
    enable = false; # to revert

    shares = {
      backup_drive = {
        path = "/mnt/storage/recordsize-1M/backup_drive";
        browseable = "no";
        "guest ok" = "no";
        "read only" = "no";
      };

      media_and_such = {
        path = "/mnt/storage/recordsize-1M/data_drive";
        browseable = "no";
        "guest ok" = "no";
        "read only" = "no";
      };
    };
  };
}
