{ hostname, selfSourceInfo }:
final: prev:
{
  lib = prev.lib // {
    skipCheck = pkg: pkg.overrideAttrs (old: { doCheck = false; });
  };

  system-flake-info = import ./system-flake-info.nix { inherit hostname selfSourceInfo; pkgs = final; };
}
