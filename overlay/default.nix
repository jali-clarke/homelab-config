{ nixos-generators, hostname, selfSourceInfo }:
final: prev: {
  inherit nixos-generators;
  load-ssh-key = import ./load-ssh-key.nix { pkgs = final; };
  sanoid = final.callPackage ./sanoid.nix { };
  system-flake-info = import ./system-flake-info.nix { inherit hostname selfSourceInfo; pkgs = final; };
}
