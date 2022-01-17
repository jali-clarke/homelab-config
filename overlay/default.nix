{ nixos-generators, hostname, selfSourceInfo }:
final: prev: {
  inherit nixos-generators;
  system-flake-info = import ./system-flake-info.nix { inherit hostname selfSourceInfo; pkgs = final; };
}
