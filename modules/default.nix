{ ... }: {
  imports = [
    ./common-config
    ./kubernetes
    ./meta
    ./nexus
    ./nginx-proxy
    ./pihole
    ./users
    ./vault
    ./zfs
  ];
}
