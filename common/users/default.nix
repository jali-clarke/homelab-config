{config, lib, ...}:
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
        default = [];
      };
    };

  config =
    let
      cfg = config.homelab-config.users;
    in
    {
      users.mutableUsers = false;
      users.users.pi = {
        hashedPassword = passwordHashes.pi;
        openssh.authorizedKeys.keys = [sshPubKeys.nixops];
        isNormalUser = true;
        extraGroups = ["wheel"] ++ cfg.extraGroups; # Enable ‘sudo’ for the user.
      };
    };
}
