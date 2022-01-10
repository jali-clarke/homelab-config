{ config, lib, ... }: {
  options.homelab-config.nginx-proxy =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      httpServiceMap = mkOption {
        type = types.attrsOf types.port;
        default = { };
      };
    };

  config =
    let
      cfg = config.homelab-config.nginx-proxy;

      mkVirtualHost = hostname: port: {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_pass_header Authorization;
            proxy_set_header Host ${hostname};
          '';
        };
      };
    in
    lib.mkIf cfg.enable {
      services.nginx = {
        enable = true;
        virtualHosts = lib.attrsets.mapAttrs mkVirtualHost cfg.httpServiceMap;

        appendHttpConfig = ''
          server {
            server_name = _;
            listen 80 default_server;
            return 404;
          }
        '';
      };
    };
}
