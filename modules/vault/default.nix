{ pkgs, config, lib, options, ... }: {
  options.homelab-config.vault =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      storagePath = mkOption {
        type = types.path;
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
      cfg = config.homelab-config.vault;
    in
    lib.mkIf cfg.enable {
      services.vault = {
        enable = true;
        package = pkgs.vault-bin; # required for the ui
        address = "${cfg.webInterface.ip}:${toString cfg.webInterface.port}";
        storageBackend = "file";
        storagePath = cfg.storagePath;
        extraConfig = ''
          ui = true
        '';
      };
    };
}
