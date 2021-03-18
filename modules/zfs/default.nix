{ config, lib, ... }: {
  options.homelab-config.zfs =
    let
      inherit (lib) types mkOption;
    in
    {
      doAutoScrub = mkOption {
        type = types.bool;
        default = true;
      };

      doAutoSnapshot = mkOption {
        type = types.bool;
        default = false;
      };

      hostId = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      zfsARCSizeMaxGB = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
      };
    };

  config =
    let
      cfg = config.homelab-config.zfs;
    in
    lib.mkMerge [
      (
        {
          boot.loader.grub.copyKernels = true;
          boot.supportedFilesystems = [ "zfs" ];
          services.zfs.autoScrub.enable = cfg.doAutoScrub;
        }
      )

      (
        lib.mkIf (cfg.zfsARCSizeMaxGB != null) {
          boot.kernelParams = [ "zfs.zfs_arc_max=${toString (cfg.zfsARCSizeMaxGB * 1024 * 1024 * 1024)}" ];
        }
      )

      (
        lib.mkIf (cfg.hostId != null) {
          networking.hostId = cfg.hostId;
        }
      )

      (
        lib.mkIf cfg.doAutoSnapshot {
          services.sanoid = {
            enable = true;
            datasets.storage = { # hardcoding the dataset name for now
              autosnap = true;
              autoprune = true;
              recursive = true;
              processChildrenOnly = true;

              hourly = 24;
              daily = 30;
              monthly = 6;
              yearly = 0;
            };
          };
        }
      )
    ];
}
