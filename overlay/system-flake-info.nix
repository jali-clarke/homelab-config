{ pkgs, hostname, selfSourceInfo }:
let
  flakeVersion = import ../lib/flake-version.nix { inherit pkgs hostname selfSourceInfo; };
in
pkgs.writeShellScriptBin "system_flake_version" ''
  echo "${flakeVersion.versionedFlakeURI} (rev date: ${flakeVersion.lastModifiedFormatted})"
''
