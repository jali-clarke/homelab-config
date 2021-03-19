{ pkgs, config, lib, ... }: {
  options.homelab-config.zfs =
    let
      inherit (lib) types mkOption;
    in
    {
      doAutoScrub = mkOption {
        type = types.bool;
        default = true;
      };

      doAutoSnapshotDataset = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      doSnapshotReplication = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              source = mkOption {
                type = types.str;
              };

              target = mkOption {
                type = types.str;
              };

              sshKey = mkOption {
                type = types.path;
              };

              sshNoVerify = mkOption {
                type = types.bool;
                default = false;
              };
            };
          }
        );

        default = null;
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

          environment.systemPackages = [
            pkgs.lz4
            pkgs.mbuffer
            pkgs.pv
          ];
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
        lib.mkIf (cfg.doAutoSnapshotDataset != null) {
          services.sanoid = {
            enable = true;
            datasets.${cfg.doAutoSnapshotDataset} = {
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

      (
        let
          cfgReplication = cfg.doSnapshotReplication;
        in
        lib.mkIf (cfgReplication != null) {
          services.syncoid = {
            enable = true;

            # relies on permission delegation
            # should do `zfs allow <user> create,mount,receive,rollback <target>` on target host
            user = "pi";
            group = "users";

            commands.${cfgReplication.source} = {
              target = cfgReplication.target;
              sshKey = cfgReplication.sshKey;

              recursive = true;
              extraArgs = [
                "--create-bookmark"
                "--compress" "lz4"
                "--no-sync-snap"
                "--skip-parent"
              ] ++ lib.optionals cfgReplication.sshNoVerify [
                "--sshoption" "StrictHostKeyChecking=no"
                "--sshoption" "UserKnownHostsFile=/dev/null"
              ];
            };
          };
        }
      )
    ];
}
