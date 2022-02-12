{ callPackage, buildKodiAddon, fetchFromGitHub, requests, six }:
buildKodiAddon rec {
  pname = "twitch";
  namespace = "plugin.video.twitch";
  version = "2.5.12";

  src = fetchFromGitHub {
    owner = "anxdpanic";
    repo = namespace;
    rev = "v${version}";
    sha256 = "sha256-A+MPVn/Q1t2NUAvflfEnOemghcnFxvwvhbCMj1JQk/U=";
  };

  propagatedBuildInputs = [
    requests
    six

    (callPackage ./script.module.python.twitch.nix { })
  ];
}
