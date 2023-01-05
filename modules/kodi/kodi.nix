{ fetchFromGitHub, kodi-wayland }:
let
  callPackage = kodi-wayland.packages.callPackage;
  otherAddons = [
    (callPackage ./addons/plugin.video.crunchyroll { })
    (callPackage ./addons/plugin.video.embycon { })
    (callPackage ./addons/plugin.video.jellycon { })
    (callPackage ./addons/plugin.video.twitch { inherit callPackage; })
  ];

  fix-osmc-skin = osmc-skin:
    osmc-skin.overrideAttrs (
      old: rec {
        name = builtins.replaceStrings [ old.version ] [ version ] old.name;
        version = "19.1.2";
        src = fetchFromGitHub {
          owner = "osmc";
          repo = "skin.osmc";
          rev = "a6b388931c1d6d6900e7e2053b197e14945d1e8b";
          sha256 = "sha256-2VSi+sRhvzbs73q6hFx92CA6aSRkSYAoSkVOQGN/1sE=";
        };
      }
    );
in
kodi-wayland.withPackages (
  addons: otherAddons ++ [
    addons.netflix
    (fix-osmc-skin addons.osmc-skin)
    addons.youtube
  ]
)
