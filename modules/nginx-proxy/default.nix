{ config, lib, ... }: {
  options.homelab-config.nginx-proxy =
    let
      inherit (lib) mkOption types;
    in
    {
      serviceMap = mkOption {
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
    {
      services.nginx = {
        enable = true;
        virtualHosts = lib.attrsets.mapAttrs mkVirtualHost cfg.serviceMap;
      };
    };
}
