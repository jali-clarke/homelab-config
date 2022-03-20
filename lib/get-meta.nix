{ pkgs }:
let
  inherit (pkgs) lib;

  hostMap = {
    atlas = {
      ipv4 = "192.168.0.103";
      mac = "b4:2e:99:a0:53:3b";
    };

    osmc = {
      ipv4 = "192.168.0.104";
      mac = "dc:a6:32:63:ec:e8";
    };

    scribe = {
      ipv4 = "192.168.0.105";
      mac = "f8:d0:27:6e:65:0e";
    };

    speet = {
      ipv4 = "192.168.0.101";
      mac = "b8:27:eb:3e:38:20";
    };

    spoot = {
      ipv4 = "192.168.0.106";
      mac = "b8:27:eb:a6:61:01";
    };

    weedle = {
      ipv4 = "192.168.0.102";
      mac = "e0:d5:5e:e4:61:74";
    };

    # virtual host on k8s
    ingress = {
      ipv4 = "192.168.0.200";
      mac = null;
    };

    ingress-external = {
      ipv4 = "192.168.0.202";
      mac = null;
    };
  };

  mkEntry = hostName: networkInfo: {
    inherit hostName;
    hostNameWithDomain = "${hostName}.jali-clarke.ca";
    networkIP = networkInfo.ipv4;
    macAddress = networkInfo.mac;
  };
in
lib.attrsets.mapAttrs mkEntry hostMap
