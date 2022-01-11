{ config, pkgs, lib, ... }: {
  options.homelab-config.k8s =
    let
      inherit (lib) types mkOption;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      isMaster = mkOption {
        type = types.bool;
        default = false;
      };

      masterIP = mkOption {
        type = types.str;
      };

      masterHostname = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      schedulable = mkOption {
        type = types.bool;
        default = true;
      };

      sshKeyPath = mkOption {
        type = types.nullOr types.path;
        default = null;
      };
    };

  config =
    let
      cfg = config.homelab-config.k8s;
      masterHostname = if cfg.isMaster then config.networking.hostName else assert (cfg.masterHostname != null); cfg.masterHostname;

      ssh = "${pkgs.openssh}/bin/ssh";
      joinCluster = pkgs.writeScriptBin "join_cluster" ''
        #!${pkgs.runtimeShell} -xe
        ${ssh} -i ${cfg.sshKeyPath} pi@${cfg.masterIP} -- "sudo cat /var/lib/kubernetes/secrets/apitoken.secret" | sudo nixos-kubernetes-node-join
      '';

      containerdConfigFile = pkgs.writeText "containerd.toml" ''
        version = 2
        root = "/var/lib/containerd/daemon"
        state = "/var/run/containerd/daemon"
        oom_score = 0
        [grpc]
          address = "/var/run/containerd/containerd.sock"
        [plugins."io.containerd.grpc.v1.cri"]
          sandbox_image = "pause:latest"
        [plugins."io.containerd.grpc.v1.cri".cni]
          bin_dir = "/opt/cni/bin"
          max_conf_num = 0
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes."io.containerd.runc.v2".options]
          SystemdCgroup = true

        [plugins."io.containerd.grpc.v1.cri".registry]
          [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
            [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
              endpoint = ["https://registry-1.docker.io"]
      '';
    in
    lib.mkIf cfg.enable (
      lib.mkMerge [
        (
          {
            networking.extraHosts = "${cfg.masterIP} ${masterHostname}";

            virtualisation.containerd.configFile = lib.mkForce containerdConfigFile;

            services.kubernetes = {
              roles = lib.optionals cfg.isMaster [ "master" ] ++ lib.optionals cfg.schedulable [ "node" ];
              masterAddress = masterHostname;
              easyCerts = true;
              addons.dns.enable = true;
              kubelet.extraOpts = "--fail-swap-on=false";
            };

            environment.systemPackages = [
              pkgs.k9s
              pkgs.kubectl
              pkgs.kubernetes
            ];

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
        )

        (
          lib.mkIf cfg.isMaster {
            services.kubernetes = {
              apiserver = {
                securePort = 443;
                advertiseAddress = cfg.masterIP;
              };
            };
          }
        )

        (
          lib.mkIf (!cfg.isMaster) {
            assertions = [
              {
                assertion = cfg.sshKeyPath != null;
                message = "worker nodes must have homelab-config.k8s.sshKeyPath set";
              }
            ];

            environment.systemPackages = [
              joinCluster
            ];

            services.kubernetes = {
              kubelet.kubeconfig.server = "https://${masterHostname}:443";
              apiserverAddress = "https://${masterHostname}:443";
            };
          }
        )
      ]
    );
}
