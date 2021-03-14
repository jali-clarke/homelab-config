{config, lib, ...}: {
  options.homelab-config.docker-support =
    let
      inherit (lib) types mkOption;
    in
    {
      usingKubernetes = mkOption {
        type = types.bool;
        default = false;
      };
    };

  config =
    let
      cfg = config.homelab-config.docker-support;
    in
    lib.mkMerge [
      (
        {
          environment.etc."docker/daemon.json".text = ''
            {
              "insecure-registries": ["docker.lan:5000"],
              "max-concurrent-uploads": 1
            }
          '';
        }
      )

      (
        lib.mkIf (!cfg.usingKubernetes) {
          virtualisation.docker.enable = true;
        }
      )
    ];
}
