{config, lib, ...}: {
  imports = [
    ./packages.nix
    ./services.nix
  ];

  options.homelab-config.k8s-support =
    let
      inherit (lib) types mkOption;
    in
    {
      masterIP = mkOption {
        type = types.str;
      };

      schedulable = mkOption {
        type = types.bool;
        default = true;
      };
    };

  config =
    let
      cfg = config.homelab-config.k8s-support;
    in
    {
      networking.extraHosts = "${cfg.masterIP} ${config.networking.hostName}";

      services.kubernetes = {
        roles = ["master"] ++ lib.optionals cfg.schedulable ["node"];
        masterAddress = config.networking.hostName;
        easyCerts = true;
        apiserver = {
          securePort = 443;
          advertiseAddress = cfg.masterIP;
        };
        addons.dns.enable = true;
        kubelet.extraOpts = "--fail-swap-on=false";
      };
    };
}
