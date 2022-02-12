{ config, lib, pkgs, ... }: {
  options.homelab-config.kodi =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      remoteControlPort = mkOption {
        type = types.port;
        default = 80;
      };
    };

  config =
    let
      cfg = config.homelab-config.kodi;
    in
    lib.mkIf cfg.enable {
      sound.enable = true;
      hardware.pulseaudio.enable = true;

      services.xserver = {
        enable = true;

        displayManager = {
          autoLogin = {
            enable = true;
            user = "pi";
          };
        };

        desktopManager.kodi.enable = true;
      };

      networking.firewall = {
        allowedTCPPorts = [ cfg.remoteControlPort ];
        allowedUDPPorts = [ cfg.remoteControlPort ];
      };
    };
}
