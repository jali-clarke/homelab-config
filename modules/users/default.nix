{ config, lib, ciphertexts, ... }:
{
  options.homelab-config.users =
    let
      inherit (lib) types mkOption;
    in
    {
      allowPasswordAuth = mkOption {
        type = types.bool;
        default = true;
      };

      authorizedKeyPaths = mkOption {
        type = types.listOf types.path;
        default = [ ];
      };

      authorizedKeysExtraActivationDeps = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };

      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };

  config =
    let
      cfg = config.homelab-config.users;
    in
    lib.mkMerge [
      (
        lib.mkIf cfg.allowPasswordAuth {
          age.secrets.pi_password_file.file = ciphertexts."pi_password_file.age";
          # note - if this is ever rotated, you MUST delete the /etc/shadow entry for the pi user before switching config
          users.users.pi.passwordFile = config.age.secrets.pi_password_file.path;
        }
      )
      {
        assertions = [
          {
            assertion = !cfg.allowPasswordAuth -> cfg.authorizedKeyPaths != [ ];
            message = "if homelab-config.users.allowPasswordAuth is false, homelab-config.users.authorizedKeyPaths must be non-empty";
          }
        ];

        users = {
          mutableUsers = false;

          # this is fine due to the assertion above and activation script below
          allowNoPasswordLogin = !cfg.allowPasswordAuth;
        };

        users.users.pi = {
          isNormalUser = true;
          extraGroups = [ "wheel" ] ++ cfg.extraGroups; # Enable ‘sudo’ for the user.
        };

        security.sudo.extraRules = [
          {
            users = [ "pi" ];
            commands = [
              {
                command = "ALL";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];
      }
      (
        lib.mkIf (cfg.authorizedKeyPaths != [ ]) {
          system.activationScripts.sshAuthorizedKeysPi = {
            deps = [ "users" "groups" ] ++ cfg.authorizedKeysExtraActivationDeps;
            text =
              let
                appendCmd = authorizedKeyPath: "cat ${authorizedKeyPath} >> $AUTHORIZED_KEYS_TMP";
              in
              ''
                AUTHORIZED_KEYS_TMP=/tmp/authorized_keys.tmp
                SSH_DIR=/home/pi/.ssh
                AUTHORIZED_KEYS_TARGET=$SSH_DIR/authorized_keys

                echo "generating $AUTHORIZED_KEYS_TARGET ..."

                mkdir -p $SSH_DIR
                chown pi:users $SSH_DIR

                rm -f $AUTHORIZED_KEYS_TMP
                ${builtins.concatStringsSep "\n" (map appendCmd cfg.authorizedKeyPaths)}

                rm -f $AUTHORIZED_KEYS_TARGET
                mv $AUTHORIZED_KEYS_TMP $AUTHORIZED_KEYS_TARGET
                chown pi:users $AUTHORIZED_KEYS_TARGET
                chmod 400 $AUTHORIZED_KEYS_TARGET

                echo "generated $AUTHORIZED_KEYS_TARGET"
              '';
          };
        }
      )
    ];
}
