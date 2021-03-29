{ config, lib, ... }: {
  options.homelab-config.nexus =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      nexusDataPath = mkOption {
        type = types.path;
      };

      dockerInterface = {
        ip = mkOption {
          type = types.str;
          default = "0.0.0.0";
        };

        port = mkOption {
          type = types.port;
          default = 5000;
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
    in
    lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers.nexus = {
        image = "sonatype/nexus3:3.30.0";

        environment = {
          INSTALL4J_ADD_VM_PARAMS = "-Xms1024m -Xmx1024m -XX:MaxDirectMemorySize=1536m -Djava.util.prefs.userRoot=$NEXUS_DATA/javaprefs";
        };

        ports = [
          "${cfg.webInterface.ip}:${toString cfg.webInterface.port}:8081/tcp"
          "${cfg.dockerInterface.ip}:${toString cfg.dockerInterface.port}:5000/tcp"
        ];

        volumes = [
          "${cfg.nexusDataPath}:/nexus-data"
        ];

        extraOptions = [
          "--hostname=nexus"

          "--cpus=1"
          "--memory=1792m"
        ];
      };
    };
}
