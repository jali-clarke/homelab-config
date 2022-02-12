{ buildKodiAddon, fetchFromGitHub, inputstreamhelper }:
buildKodiAddon rec {
  pname = "crunchyroll";
  namespace = "plugin.video.crunchyroll";
  version = "3.2.0";

  src = fetchFromGitHub {
    owner = "MrKrabat";
    repo = namespace;
    rev = "00279f4d0d8c397052cd09c79aff6a0ca3cf731d";
    sha256 = "sha256-KQlZpJ/fAs9wLC2vxdewjRNhaD8eJakjA0BG8Q+NdBE=";
  };

  propagatedBuildInputs = [
    inputstreamhelper
  ];
}
