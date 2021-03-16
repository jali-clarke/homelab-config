{pkgs, ...}:
let
  piholeLanConf = pkgs.writeText "lan.conf" ''
    # bare-metal infra

    host-record=speet.lan,speet,192.168.0.101
    host-record=weedle.lan,weedle,192.168.0.102
    host-record=atlas.lan,atlas,192.168.0.103
    host-record=osmc.lan,osmc,192.168.0.104
    host-record=scribe.lan,scribe,192.168.0.105

    # bare-metal services

    cname=pihole.lan,pihole,atlas.lan

    # k8s services

    host-record=docker.lan,docker,192.168.0.203

    # k8s ingress

    host-record=ingress.lan,ingress,192.168.0.200

    cname=emby.lan,emby,ingress.lan
    cname=web.dev.lan,files.dev.lan,dev.lan,dev,ingress.lan
    cname=web.dev-staging.lan,files.dev-staging.lan,dev-staging.lan,dev-staging,ingress.lan
    cname=grafana.lan,grafana,ingress.lan
    cname=markov.lan,markov,ingress.lan
    cname=markov-app.lan,markov-app,ingress.lan
    cname=torrents.lan,torrents,ingress.lan
  '';
in
{
  virtualisation.oci-containers.containers.pihole = {
    image = "pihole/pihole:4.2.2-1";

    environment = {
      IPv6 = "False";
    };

    ports = [
      "80:80/tcp"
      "53:53/tcp"
      "53:53/udp"
    ];

    volumes = [
      "/mnt/stroage/recordsize-128K/pihole/config:/etc/pihole"
      "/mnt/stroage/recordsize-128K/pihole/dnsmasq:/etc/dnsmasq.d"
      "${piholeLanConf}:/etc/dnsmasq.d/02-lan.conf:ro"
    ];

    extraOptions = [
      "--hostname=pihole"
      "--dns=127.0.0.1"

      "--cpus=0.1"
      "--memory=128m"
    ];
  };
}
