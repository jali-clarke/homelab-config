{ pkgs, config, lib, options, ... }: {
  options.homelab-config.nexus =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      nexusHome = {
        create = mkOption {
          type = types.bool;
          default = true;
        };
        path = mkOption {
          type = types.path;
        };
      };

      webInterface = {
        ip = mkOption {
          type = types.str;
          default = "0.0.0.0";
        };

        port = mkOption {
          type = types.port;
          default = 80;
        };
      };
    };

  config =
    let
      cfg = config.homelab-config.nexus;
      implNexusCfg = config.services.nexus;
      implNexusOpts = options.services.nexus;
    in
    lib.mkIf cfg.enable {
      services.nexus = rec {
        enable = cfg.enable;
        listenAddress = cfg.webInterface.ip;
        listenPort = cfg.webInterface.port;
        home = cfg.nexusHome.path;

        # see if there's an update in nixpkgs before bumping this manually
        package = pkgs.nexus.overrideAttrs (
          old: rec {
            version = "3.32.0-03";
            sourceRoot = "${old.pname}-${version}";
            src = pkgs.fetchurl {
              url = "https://sonatype-download.global.ssl.fastly.net/nexus/3/nexus-${version}-unix.tar.gz";
              sha256 = "17cgbpv1id4gbp3c42pqc3dxnh36cm1c77y7dysskyml4qfh5f7m";
            };
          }
        );

        jvmOpts = ''
          ${implNexusOpts.jvmOpts.default}
          -Djava.util.prefs.userRoot=${home}/nexus3/javaprefs
        '';
      };

      users.users.${implNexusCfg.user}.createHome = lib.mkForce cfg.nexusHome.create;
    };
}
