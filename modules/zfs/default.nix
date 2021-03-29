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

      doAutoSMART = mkOption {
        type = types.bool;
        default = true;
      };

      sanoidOpts = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = false;
              };

              dataset = mkOption {
                type = types.str;
              };

              autosnap = mkOption {
                type = types.bool;
              };

              autoprune = mkOption {
                type = types.bool;
                default = true;
              };

              processChildrenOnly = mkOption {
                type = types.bool;
                default = true;
              };
            };
          }
        );

        default = null;
      };

      syncoidOpts = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = false;
              };

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
        let
          sanoidOpts = cfg.sanoidOpts;
          userPerms = "bookmark,create,hold,mount,receive,rollback,send";
        in
        lib.mkIf (sanoidOpts != null) {
          services.sanoid = {
            enable = true;
            datasets.${sanoidOpts.dataset} = {
              autosnap = sanoidOpts.autosnap;
              autoprune = sanoidOpts.autoprune;
              recursive = true;
              processChildrenOnly = sanoidOpts.processChildrenOnly;

              hourly = 24;
              daily = 30;
              monthly = 6;
              yearly = 0;
            };
          };

          systemd.services.zfs-pi-delegation = {
            description = "Gives the pi user zfs permissions";
            serviceConfig = {
              RemainAfterExit = "yes";
              Type = "oneshot";
            };

            script = "/run/booted-system/sw/bin/zfs allow pi ${userPerms} ${sanoidOpts.dataset}";
            after = [ "zfs.target" ];
            wantedBy = [ "multi-user.target" ];
          };
        }
      )

      (
        let
          syncoidOpts = cfg.syncoidOpts;
        in
        lib.mkIf (syncoidOpts != null) {
          assertions = [
            {
              assertion = cfg.sanoidOpts != null;
              message = "if syncoidOpts is set, sanoidOpts must be set as well";
            }
          ];

          services.syncoid = {
            enable = true;

            user = "pi";
            group = "users";

            commands.${syncoidOpts.source} = {
              target = syncoidOpts.target;
              sshKey = syncoidOpts.sshKey;

              recursive = true;
              extraArgs = [
                "--create-bookmark"
                "--compress"
                "lz4"
                "--no-sync-snap"
                "--skip-parent"
              ] ++ lib.optionals syncoidOpts.sshNoVerify [
                "--sshoption"
                "StrictHostKeyChecking=no"
                "--sshoption"
                "UserKnownHostsFile=/dev/null"
              ];
            };
          };
        }
      )

      (
        {
          services.smartd = {
            enable = cfg.doAutoSMART;

            autodetect = true;
            extraOptions = [
              "--interval=${toString (24 * 3600)}" # every day
            ];
          };
        }
      )
    ];
}
