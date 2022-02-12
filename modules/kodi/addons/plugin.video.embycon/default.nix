{ buildKodiAddon, fetchFromGitHub }:
buildKodiAddon rec {
  pname = "embycon";
  namespace = "plugin.video.embycon";
  version = "1.10.18";

  src = fetchFromGitHub {
    owner = "faush01";
    repo = namespace;
    rev = "ce0a4b2c9148be8968c3c7d8fd640756e0efc570";
    sha256 = "sha256-ralXNKiIEYGPSdzW6zQgDU8Gfv0q0SEzXBdCwrkwZxU=";
  };

  # ignoring these; pil should be provided from the env, the others seem optional
  # propagatedBuildInputs = [
  #   pil # expects 1.1.7
  #   "skin.estuary_embycon" # expects 1.0.0
  #   "screensaver.embycon" # expects 1.0.0
  # ];
}
