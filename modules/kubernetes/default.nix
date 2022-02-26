{ config, pkgs, lib, options, ... }: {
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
              kubelet.extraOpts = "--fail-swap-on=false";

              addons.dns = {
                enable = true;
                # use arm64 image where needed
                coredns = options.services.kubernetes.addons.dns.coredns.default // lib.optionalAttrs (pkgs.system == "aarch64-linux") {
                  imageDigest = "sha256:e98e05b50afc6606d3e0a66e264175910651746262e4a4823299ec6c827ef72a";
                  sha256 = "sha256-qIXGQszDDnmsVhPGzbDoz8TrS1OK8VRWcQmvicgV3Zk=";
                };
              };
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

            services.kubernetes = {
              kubelet.kubeconfig.server = "https://${masterHostname}:443";
              apiserverAddress = "https://${masterHostname}:443";
            };

            systemd.services.kubernetes-auto-join-cluster = {
              description = "Joins the cluster automatically";
              serviceConfig = {
                RemainAfterExit = "yes";
                Type = "oneshot";
              };

              script = ''
                SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
                TOKEN="$(${pkgs.openssh}/bin/ssh $SSH_OPTS -i ${cfg.sshKeyPath} pi@${cfg.masterIP} -- sudo cat /var/lib/kubernetes/secrets/apitoken.secret)"
                echo "$TOKEN" | /run/current-system/sw/bin/nixos-kubernetes-node-join
              '';
              after = [ "kubelet.service" ];
              wantedBy = [ "kubelet.service" ];
            };
          }
        )
      ]
    );
}
