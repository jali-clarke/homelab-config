{ ... }: {
  services.nfs.server = {
    enable = true;
    nproc = 4; # 4 threads
    hostName = "192.168.0.103";

    exports = ''
      /mnt/storage/recordsize-128K 192.168.0.0/24(rw,no_subtree_check,no_root_squash)
      /mnt/storage/recordsize-1M 192.168.0.0/24(rw,no_subtree_check,no_root_squash)
    '';
  };

  # still need to do `sudo smbpasswd -a pi`
  services.samba = {
    enable = true;

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
