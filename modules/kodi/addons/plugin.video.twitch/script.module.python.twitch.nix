{ callPackage, buildKodiAddon, fetchFromGitHub, requests, six }:
buildKodiAddon rec {
  pname = "script-twitch";
  namespace = "script.module.python.twitch";
  version = "2.0.19";

  src = fetchFromGitHub {
    owner = "anxdpanic";
    repo = namespace;
    rev = "v${version}";
    sha256 = "sha256-4o943WpwQ+dCIt6ZiFKiMhsz8/YUcnwysoh0IXeVFjY=";
  };

  propagatedBuildInputs = [
    requests
    six
  ];
}
