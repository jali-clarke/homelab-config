{ nixos-generators }:
final: prev: {
  inherit nixos-generators;
  sanoid = final.callPackage ./sanoid.nix { };
}
