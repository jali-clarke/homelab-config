{config, pkgs, lib, ...}: {
  imports = [
    ./packages.nix
    ./services.nix
  ];

  options.homelab-config.k8s-support =
    let
      inherit (lib) types mkOption;
    in
    {
      workerIP = mkOption {
        type = types.string;
      };

      masterIP = mkOption {
        type = types.string;
      };

      masterHostname = mkOption {
        type = types.string;
      };

      schedulable = mkOption {
        type = types.bool;
        default = true;
      };
    };

  config =
    let
      cfg = config.homelab-config.k8s-support;

      joinCluster = pkgs.writeScriptBin "join_cluster" ''
        #!${pkgs.runtimeShell} -xe

        ssh=${pkgs.openssh}/bin/ssh
        $ssh pi@${cfg.masterIP} -- "sudo cat /var/lib/kubernetes/secrets/apitoken.secret" | sudo nixos-kubernetes-node-join
      '';
    in
    {
      environment.systemPackages = [
        joinCluster
      ];

      networking.extraHosts = ''
        ${cfg.masterIP} ${cfg.masterHostname}
        ${cfg.workerIP} ${config.networking.hostName}
      '';

      services.kubernetes = {
        roles = lib.optionals cfg.schedulable ["node"];
        masterAddress = cfg.masterHostname;
        easyCerts = true;
        kubelet.kubeconfig.server = "https://${cfg.masterHostname}:443";
        apiserverAddress = "https://${cfg.masterHostname}:443";
        addons.dns.enable = true;
        kubelet.extraOpts = "--fail-swap-on=false";
      };
    };
}
