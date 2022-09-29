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

      package = mkOption {
        type = types.package;
        default = pkgs.callPackage ./kodi.nix { };
      };
    };

  config =
    let
      cfg = config.homelab-config.kodi;

      advancedSettings = pkgs.writeText "advancedsettings.xml" ''
        <advancedsettings version="1.0">
          <services>
            <esallinterfaces>true</esallinterfaces>
            <webserver>true</webserver>
            <webserverport>${toString cfg.remoteControlPort}</webserverport>
            <webserverauthentication>false</webserverauthentication>
            <webserverusername>pi</webserverusername>
            <webserverpassword></webserverpassword>
            <webserverssl>false</webserverssl>
          </services>
        </advancedsettings>
      '';
    in
    lib.mkIf cfg.enable {
      sound.enable = true;
      hardware.pulseaudio.enable = true;

      services.cage = {
        enable = true;
        user = "pi";
        program = "${cfg.package}/bin/kodi-standalone";
      };

      networking.firewall = {
        allowedTCPPorts = [ cfg.remoteControlPort ];
        allowedUDPPorts = [ cfg.remoteControlPort ];
      };

      system.activationScripts.writeKodiAdvancedSettings = {
        deps = [ "users" "groups" ];
        text = ''
          USERDATA_DIR="/home/${config.services.cage.user}/.kodi/userdata"
          ADVANCEDSETTINGS_XML="$USERDATA_DIR/advancedsettings.xml"

          mkdir -p "$USERDATA_DIR"
          chmod 755 "$USERDATA_DIR"
          chown pi "$USERDATA_DIR"

          rm -f "$ADVANCEDSETTINGS_XML"
          cp ${advancedSettings} "$ADVANCEDSETTINGS_XML"
          chmod 444 "$ADVANCEDSETTINGS_XML"
          chown pi "$ADVANCEDSETTINGS_XML"
        '';
      };
    };
}
