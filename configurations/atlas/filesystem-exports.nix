{...}: {
  services.nfs.server = {
    enable = true;
    nproc = 4; # 4 threads
    hostName = "192.168.0.103";

    exports = ''
      /mnt/storage/recordsize-128K 192.168.0.0/24(rw,no_subtree_check,no_root_squash)
      /mnt/storage/recordsize-1M 192.168.0.0/24(rw,no_subtree_check,no_root_squash)
    '';
  };
}
