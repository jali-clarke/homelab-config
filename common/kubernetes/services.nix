{...}: {
  # stupid proxy since ad-hoc nfs mounts are really fiddly for some reason
  fileSystems."/.DUMMY_NFS_MOUNT" = {
    device = "FAKE_HOST:FAKE_PATH";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
  };

  environment.etc."docker/daemon.json".text = ''
    {
      "insecure-registries": ["docker.lan:5000"],
      "max-concurrent-uploads": 1
    }
  '';
}
