{pkgs, swapSizeGB, hddName}:
pkgs.writeScriptBin "install-nixos" ''
  #!${pkgs.bash}/bin/bash -xe

  parted_cmd="${pkgs.parted}/bin/parted ${hddName} --"

  $parted_cmd mklabel gpt
  $parted_cmd mkpart primary 512MiB -${swapSizeGB}GiB # /
  $parted_cmd mkpart primary linux-swap -${swapSizeGB}GiB 100% # swap
  $parted_cmd mkpart ESP fat32 1MiB 512MiB # /boot
  $parted_cmd set 3 esp on

  mkfs.ext4 -L nixos ${hddName}1
  mkswap -L swap ${hddName}2
  mkfs.fat -F 32 -n boot ${hddName}3

  mkdir -p /mnt
  mount /dev/disk/by-label/nixos /mnt
  mkdir -p /mnt/boot
  mount /dev/disk/by-label/boot /mnt/boot

  swapon ${hddName}2

  nixos-generate-config --root /mnt
  rm /mnt/etc/nixos/configuration.nix

  cp ${./bundled-configuration.nix} /mnt/etc/nixos/configuration.nix
  cp -r ${../common} /mnt/etc/nixos/common

  nixos-install --no-root-passwd
  reboot
''
