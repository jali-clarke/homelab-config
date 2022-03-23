{ config, pkgs, lib, ciphertexts, ... }:
let
  secretFilePi = secretFilePath: {
    file = secretFilePath;
    owner = "pi";
  };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  age.secrets = {
    id_cerberus = secretFilePi ciphertexts."id_cerberus.age";
    "id_cerberus.pub" = secretFilePi ciphertexts."id_cerberus.pub.age";
    "id_dev_env.pub" = secretFilePi ciphertexts."id_dev_env.pub.age";
    "wg_server_key".file = ciphertexts."wg_server_key.age";
  };

  homelab-config.router.tables = {
    enable = true;
    allowedIcmpInterfaces = [ "eth0" ];
    allowedTcpInterfaces.eth0 = [ 22 ];
  };

  homelab-config.users = {
    allowPasswordAuth = false;
    authorizedKeyPaths = [
      config.age.secrets."id_dev_env.pub".path
    ];

    authorizedKeysExtraActivationDeps = [ "agenix" ];
  };

  networking.hostName = "cerberus";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
