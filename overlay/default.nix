{ hostname, selfSourceInfo }:
final: prev: {
  system-flake-info = import ./system-flake-info.nix { inherit hostname selfSourceInfo; pkgs = final; };
}
