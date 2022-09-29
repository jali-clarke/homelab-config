{ config, lib, ... }:
let
  cfg = config.hardware.opengl;
in
{
  systemd.tmpfiles.rules = [
    "L+ /run/opengl-driver-32 - - - - ${cfg.package32}"
  ];

  environment.sessionVariables.LD_LIBRARY_PATH = lib.mkIf cfg.setLdLibraryPath [ "/run/opengl-driver-32/lib" ];
}
