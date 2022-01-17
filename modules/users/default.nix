{ config, lib, ciphertexts, ... }:
let
  passwordHashes = import ./pw-hashes.nix;
  sshPubKeys = import ./ssh-pub-keys.nix;
in
{
  options.homelab-config.users =
    let
      inherit (lib) types mkOption;
    in
    {
      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };

  config =
    let
      cfg = config.homelab-config.users;
      secretFile = secretFilePath: {
        file = secretFilePath;
        owner = "pi";
      };
    in
    {
      age.secrets.id_rsa_nixops = secretFile ciphertexts."id_rsa_nixops.age";
      age.secrets."id_rsa_nixops.pub" = secretFile ciphertexts."id_rsa_nixops.pub.age";

      users.mutableUsers = false;
      users.users.pi = {
        hashedPassword = passwordHashes.pi;
        openssh.authorizedKeys.keys = [ sshPubKeys.nixops ];
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
    };
}
