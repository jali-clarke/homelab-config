{ ... }: {
  imports = [
    ./acme-cloudflare
    ./common-config
    ./kodi
    ./kubernetes
    ./meta
    ./nexus
    ./nginx-proxy
    ./pihole
    ./router
    ./users
    ./vault
    ./zfs
  ];
}
