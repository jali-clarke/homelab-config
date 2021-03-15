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

  # !!! hack to get image import working on arm64 for coredns
  systemd.services.kubelet.preStart =
  let
    cfg = config.services.kubernetes.kubelet;
  in
  lib.mkForce ''
    ${lib.concatMapStrings (img: ''
      echo "Seeding container image: ${img}"
      ${if (lib.hasSuffix "gz" img) then
        ''${pkgs.gzip}/bin/zcat "${img}" | ${pkgs.containerd}/bin/ctr -n k8s.io image import --all-platforms -''
      else
        ''${pkgs.coreutils}/bin/cat "${img}" | ${pkgs.containerd}/bin/ctr -n k8s.io image import --all-platforms -''
      }
    '') cfg.seedDockerImages}
    rm /opt/cni/bin/* || true
    ${lib.concatMapStrings (package: ''
      echo "Linking cni package: ${package}"
      ln -fs ${package}/bin/* /opt/cni/bin
    '') cfg.cni.packages}
  '';
}
