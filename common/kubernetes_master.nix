{config, pkgs, ...}:
let
  metaconfig = import ./metaconfig.nix;
in
{
  networking.extraHosts = "${metaconfig.kubernetesMasterAddress} ${metaconfig.kubernetesMasterHostname}";

  services.kubernetes = {
    roles = ["master" "node"]; # remove "node" if you want the master to be unschedulable (best practice)
    masterAddress = metaconfig.kubernetesMasterHostname;
    easyCerts = true;
    apiserver = {
      securePort = 443;
      advertiseAddress = metaconfig.kubernetesMasterAddress;
    };
    addons.dns.enable = true;
    kubelet.extraOpts = "--fail-swap-on=false";
  };
}

