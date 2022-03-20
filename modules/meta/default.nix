{ pkgs, lib, ... }:
{
  options.homelab-config.meta =
    let
      inherit (lib) mkOption types;
    in
    # consider this to be readonly; do not set the option yourself
    mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }: {
            options = {
              hostName = mkOption {
                type = types.str;
              };

              hostNameWithDomain = mkOption {
                type = types.str;
              };

              macAddress = mkOption {
                type = types.nullOr types.str;
              };

              networkIP = mkOption {
                type = types.str;
              };
            };
          }
        )
      );

      default = import ../../lib/get-meta.nix { inherit pkgs; };
    };
}
