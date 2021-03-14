{pkgs, ...}:
let
  metaconfig = import ./metaconfig.nix;

  joinCluster = pkgs.writeScriptBin "join_cluster" ''
    #!${pkgs.runtimeShell} -xe

    ssh=${pkgs.openssh}/bin/ssh
    $ssh pi@${metaconfig.kubernetesMasterAddress} -- "sudo cat /var/lib/kubernetes/secrets/apitoken.secret" | sudo nixos-kubernetes-node-join
  '';
in
{
  imports = [
    ./packages.nix
    ./services.nix
  ];

  environment.systemPackages = [
    joinCluster
  ];

  networking.extraHosts = "${metaconfig.kubernetesMasterAddress} ${metaconfig.kubernetesMasterHostname}";

  services.kubernetes = {
    roles = ["node"];
    masterAddress = metaconfig.kubernetesMasterHostname;
    easyCerts = true;
    kubelet.kubeconfig.server = "https://${metaconfig.kubernetesMasterHostname}:443";
    apiserverAddress = "https://${metaconfig.kubernetesMasterHostname}:443";
    addons.dns.enable = true;
    kubelet.extraOpts = "--fail-swap-on=false";
  };
}
