{config, lib, ...}: {
  options.homelab-config.zfs-support =
    let
      inherit (lib) types mkOption;
    in
    {
      doAutoScrub = mkOption {
        type = types.bool;
        default = true;
      };

      hostId = mkOption {
        type = types.nullOr types.string;
        default = null;
      };

      zfsARCSizeMaxGB = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
      };
    };

  config =
    let
      cfg = config.homelab-config.zfs-support;
    in
    lib.mkMerge [
      (
        {
          boot.loader.grub.copyKernels = true;
          boot.supportedFilesystems = ["zfs"];
          services.zfs.autoScrub.enable = cfg.doAutoScrub;
        }
      )

      (
        lib.mkIf (cfg.zfsARCSizeMaxGB != null) {
          boot.kernelParams = ["zfs.zfs_arc_max=${toString (cfg.zfsARCSizeMaxGB * 1024 * 1024 * 1024)}"];
        }
      )

      (
        lib.mkIf (cfg.hostId != null) {
          networking.hostId = cfg.hostId;
        }
      )
    ];
}
