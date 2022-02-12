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
          lightdm.enable = true;
          defaultSession = "kodi";
        };

        desktopManager.kodi = {
          enable = true;
          package = pkgs.callPackage ./kodi.nix { };
        };
      };
    };
}
