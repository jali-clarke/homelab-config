{ nixos-generators, hostname, selfSourceInfo }:
final: prev: {
  inherit nixos-generators;

  agenix = final.writeShellScriptBin "agenix" ''
    export EDITOR=${final.vim}/bin/vim
    exec ${prev.agenix}/bin/agenix "$@"
  '';

  sanoid = final.callPackage ./sanoid.nix { };
  system-flake-info = import ./system-flake-info.nix { inherit hostname selfSourceInfo; pkgs = final; };
}
