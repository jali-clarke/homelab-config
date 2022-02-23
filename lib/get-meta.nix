{ pkgs }:
let
  inherit (pkgs) lib;

  ipMap = {
    atlas = "192.168.0.103";
    osmc = "192.168.0.104";
    scribe = "192.168.0.105";
    speet = "192.168.0.101";
    spoot = "192.168.0.106";
    weedle = "192.168.0.102";

    # virtual host on k8s
    ingress = "192.168.0.200";
    ingress-external = "192.168.0.202";
  };

  mkEntry = hostName: networkIP: {
    inherit hostName networkIP;
    hostNameWithDomain = "${hostName}.jali-clarke.ca";
  };
in
lib.attrsets.mapAttrs mkEntry ipMap
