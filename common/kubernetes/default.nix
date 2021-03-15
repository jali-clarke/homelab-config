{config, pkgs, lib, ...}: {
  imports = [
    ../docker.nix
    ./packages.nix
    ./services.nix
  ];

  options.homelab-config.k8s-support =
    let
      inherit (lib) types mkOption;
    in
    {
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
    };

  config =
    let
      cfg = config.homelab-config.k8s-support;
      masterHostname = if cfg.isMaster then config.networking.hostName else assert (cfg.masterHostname != null); cfg.masterHostname;

      ssh = "${pkgs.openssh}/bin/ssh";
      joinCluster = pkgs.writeScriptBin "join_cluster" ''
        #!${pkgs.runtimeShell} -xe
        ${ssh} pi@${cfg.masterIP} -- "sudo cat /var/lib/kubernetes/secrets/apitoken.secret" | sudo nixos-kubernetes-node-join
      '';
    in
    lib.mkMerge [
      (
        {
          networking.extraHosts = "${cfg.masterIP} ${masterHostname}";

          services.kubernetes = {
            roles = lib.optionals cfg.isMaster ["master"] ++ lib.optionals cfg.schedulable ["node"];
            masterAddress = masterHostname;
            easyCerts = true;
            addons.dns.enable = true;
            kubelet.extraOpts = "--fail-swap-on=false";
          };
        }
      )

      (
        if cfg.isMaster
          then
          {
            services.kubernetes = {
              apiserver = {
                securePort = 443;
                advertiseAddress = cfg.masterIP;
              };
            };
          }
          else
          {
            environment.systemPackages = [
              joinCluster
            ];

            services.kubernetes = {
              kubelet.kubeconfig.server = "https://${cfg.masterHostname}:443";
              apiserverAddress = "https://${cfg.masterHostname}:443";
            };
          }
      )
    ];
}
