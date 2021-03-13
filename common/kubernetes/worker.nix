{...}:
let
  metaconfig = import ./metaconfig.nix;
in
{
  import = [
    ./packages.nix
    ./services.nix
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

