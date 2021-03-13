{config, lib, ...}: {
  options.homelab-config.zfs-support =
    let
      inherit (lib) types mkOption;
    in
    {
      zfsARCSizeMaxGB = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
      };

      doAutoScrub = mkOption {
        type = types.bool;
        default = true;
      }
    };

  config =
    let
      cfg = config.homelab-config.zfs-support;
    in
    lib.mkMerge [
      (
        {
          boot.supportedFilesystems = ["zfs"];
          services.zfs.autoScrub.enable = cfg.doAutoScrub;
        }
      )

      (
        lib.mkIf (cfg.zfsARCSizeMaxGB != null) {
          boot.kernelParams = ["zfs.zfs_arc_max=${cfg.zfsARCSizeGB * 1024 * 1024 * 1024}"];
        }
      )
    ];
}
