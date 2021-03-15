{config, pkgs, lib, ...}: {
  imports = [
    ../docker.nix
  ];

  # let k8s support figure out whether to enable docker service and etc
  homelab-config.docker-support.usingKubernetes = true;

  # stupid proxy since ad-hoc nfs mounts are really fiddly for some reason
  fileSystems."/.DUMMY_NFS_MOUNT" = {
    device = "FAKE_HOST:FAKE_PATH";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
  };
}
