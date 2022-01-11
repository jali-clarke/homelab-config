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
        type = types.attrsOf (
          types.submodule {
            options = {
              port = mkOption {
                type = types.port;
              };

              extraConfig = mkOption {
                type = types.nullOr types.lines;
                default = null;
              };
            };
          }
        );

        default = { };
      };

      httpsServiceMap = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              port = mkOption {
                type = types.port;
              };

              certPath = mkOption {
                type = types.path;
              };

              privateKeyPath = mkOption {
                type = types.path;
              };

              extraConfig = mkOption {
                type = types.lines;
                default = "";
              };
            };
          }
        );

        default = { };
      };
    };

  config =
    let
      cfg = config.homelab-config.nginx-proxy;

      mkHttpVirtualHost = hostname: portWithConfig: {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString portWithConfig.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_pass_header Authorization;
            proxy_set_header Host ${hostname};
            ${portWithConfig.extraConfig}
          '';
        };
      };

      mkHttpsVirtualHost = hostname: portWithConfig: mkHttpVirtualHost hostname portWithConfig // {
        forceSSL = true;
        sslCertificate = portWithConfig.certPath;
        sslCertificateKey = portWithConfig.privateKeyPath;
      };
    in
    lib.mkIf cfg.enable {
      services.nginx = {
        enable = true;
        virtualHosts = lib.attrsets.mapAttrs mkHttpVirtualHost cfg.httpServiceMap // lib.attrsets.mapAttrs mkHttpsVirtualHost cfg.httpsServiceMap;

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
