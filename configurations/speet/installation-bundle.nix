{pkgs}:
pkgs.writeScriptBin "install-nixos" ''
  #!${pkgs.bash}/bin/bash -xe

  cp ${./bundled-configuration.nix} /etc/nixos/configuration.nix
  cp -r ${../common} /etc/nixos/common

  nixos-rebuild switch
  reboot
''
