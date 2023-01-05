{ buildKodiAddon, fetchzip, dateutil, kodi-six, requests, signals, six, websocket }:
buildKodiAddon rec {
  pname = "jellycon";
  namespace = "plugin.video.jellycon";
  version = "0.6.1";

  src = fetchzip {
    url = "https://repo.jellyfin.org/releases/client/kodi/py3/plugin.video.jellycon/plugin.video.jellycon-${version}+py3.zip";
    sha256 = "sha256-Srjc8tWyf9SD026xXFf4Fe+lRm3cIaj1uXOkSonUVPg=";
  };

  propagatedBuildInputs = [
    dateutil
    kodi-six
    requests
    signals
    six
    websocket
  ];
}
