{ kodi }:
let
  callPackage = kodi.packages.callPackage;
  otherAddons = [
    
  ];
in
kodi.withPackages (
  addons: otherAddons ++ [
    addons.netflix
    addons.youtube
  ]
)
