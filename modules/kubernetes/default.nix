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
    in
    lib.mkIf cfg.enable (
      lib.mkMerge [
        (
          {
            networking.extraHosts = "${cfg.masterIP} ${masterHostname}";

            virtualisation.containerd = {
              settings = {
                plugins."io.containerd.grpc.v1.cri" = lib.mkForce {
                  # keep this more-or-less in sync with <nixpkgs>/nixos/modules/services/cluster/kubernetes/default.nix
                  # we do this for two reasons (ref <nixpkgs>/nixos/modules/virtualisation/containerd.nix):
                  #   0. if we have zfs enabled, it will try (and fail!) to use it as a snapshotter
                  #   1. the cni plugins provided at ${pkgs.cni-plugins}/bin are missing flannel

                  sandbox_image = "pause:latest";

                  cni = {
                    bin_dir = "/opt/cni/bin";
                    max_conf_num = 0;
                  };

                  containerd.runtimes.runc = {
                    runtime_type = "io.containerd.runc.v2";
                    options.SystemdCgroup = true;
                  };
                };
              };
            };

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
