{config, pkgs, ...}:
let
  passwordHashes = import ./pw-hashes.nix;
  sshPubKeys = import ./ssh-pub-keys.nix;
in
{
  users.mutableUsers = false;
  users.users.pi = {
    hashedPassword = passwordHashes.pi;
    openssh.authorizedKeys.keys = [sshPubKeys.nixops];
    isNormalUser = true;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    packages = [
      pkgs.vim
    ];
  };
}
