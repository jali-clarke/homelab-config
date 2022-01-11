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

              forwardProto = mkOption {
                type = types.bool;
                default = false;
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

      mkHttpVirtualHost = hostname: port: {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_pass_header Authorization;
            proxy_set_header Host ${hostname};
          '';
        };
      };

      mkHttpsVirtualHost = hostname: portWithCertAndKey: {
        forceSSL = true;
        sslCertificate = portWithCertAndKey.certPath;
        sslCertificateKey = portWithCertAndKey.privateKeyPath;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString portWithCertAndKey.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_pass_header Authorization;
            proxy_set_header Host ${hostname};
            ${if portWithCertAndKey.forwardProto then "proxy_set_header X-Forwarded-Proto \"https\";" else ""}
          '';
        };
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
