{ kodi }:
let
  callPackage = kodi.packages.callPackage;
  otherAddons = [
    (callPackage ./addons/plugin.video.embycon { })
  ];
in
kodi.withPackages (
  addons: otherAddons ++ [
    addons.netflix
    addons.youtube
  ]
)
