{ pkgs }:
let
  inherit (pkgs) lib;

  ipMap = {
    atlas = "192.168.0.103";
    osmc = "192.168.0.104";
    scribe = "192.168.0.105";
    speet = "192.168.0.101";
    weedle = "192.168.0.102";

    # virtual host on k8s
    ingress = "192.168.0.200";
  };

  mkEntry = hostName: networkIP: {
    inherit hostName networkIP;
    hostNameWithDomain = "${hostName}.lan";
  };
in
lib.attrsets.mapAttrs mkEntry ipMap
