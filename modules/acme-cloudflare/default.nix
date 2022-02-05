{ config, lib, ... }: {
  options.homelab-config.acme-cloudflare =
    let
      inherit (lib) mkOption types;
    in
    {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      credentialsFile = mkOption {
        type = types.path;
      };

      domains = mkOption {
        # for each domain, it will create the cert in /var/lib/acme/${domain}
        type = types.listOf types.nonEmptyStr;
      };

      readableByGroup = mkOption {
        type = types.nullOr types.nonEmptyStr;
        default = null;
      };

      reloadServices = mkOption {
        type = types.listOf types.nonEmptyStr;
        default = [ ];
      };
    };

  config =
    let
      cfg = config.homelab-config.acme-cloudflare;

      mkCertConfig = domain: lib.nameValuePair domain (
        {
          inherit (cfg) credentialsFile reloadServices;
          dnsProvider = "cloudflare";
        } // lib.optionalAttrs (cfg.readableByGroup != null) {
          group = cfg.readableByGroup;
        }
      );
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.domains != [ ];
          message = "config.homelab-config.acme-cloudflare.domains cannot be empty";
        }
      ];

      security.acme = {
        acceptTerms = true;
        defaults.email = "jinnah.ali-clarke@outlook.com";
        certs = builtins.listToAttrs (map mkCertConfig cfg.domains);
      };
    };
}
