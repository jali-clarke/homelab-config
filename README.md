# homelab-config

configuration as code for our homelab

## what / why

i've been in a number of situations where i had to do a rebuild of our homelab machines due to either disk failure, hardware upgrades, etc, and this is kind of annoying to do when your (brain) memory isn't amazing.  it's especially annoying when it isn't reproduceable.

enter the almighty [NixOS](https://nixos.org/) - an OS whose package manager and configuration language is [Nix](https://nixos.org/explore.html).  this allows us to declaratively define configuration for entire systems and even share / modularize configuration across systems.  with [nix flakes](https://nixos.wiki/wiki/Flakes), this becomes almost 100% reproduceable across time and machines.

## how to use

### prerequisites

* `nix` with [flakes](https://nixos.wiki/wiki/Flakes) support
* an `x86_64-linux` system in order to build the [bootstrap images](#bootstrap-images)
* an internet connection on each machine that you plan to set up

### bootstrap images

in order to actually use these configs on a fresh system, we need to create some images to facilitate installation:

1. clone this repo and `cd` into it
2. `nix develop`
3. prep and use a bootstrap image: [for x86_64-linux systems](#for-x86_64-linux-systems), [for aarch64-linux systems](#for-aarch64-linux-systems)

#### for `x86_64-linux` systems

1. create the [bootstrap-bill](#bootstrap-bill) image by doing `build_bootstrap_bill`
2. flash the resulting image to a usb drive
3. boot from that usb drive
4. mount hard disks as necessary (including creation of `zfs` pools / datasets) and then [nixos-generate-config](https://nixos.wiki/wiki/Nixos-generate-config)
5. copy the `hardware-configuration.nix` back to this repo into the configuration dir of your choice, reference it correctly in the corresponding `configuration.nix` and commit + push it.  delete both `hardware-configuration.nix` and `configuration.nix` from the machine but not this repo
6. on the machine (either via ssh or locally) `sudo nixos-install --no-root-passwd --flake github:jali-clarke/homelab-config#${configuration_name}`
7. reboot
8. see relevant `manual steps` for the chosen configuration

#### for `aarch64-linux` systems

for raspberry pis specifically

1. create the [pi-baker](#pi-baker) image by doing `build_pi_baker`
2. flash the resulting image to a micro sd card
3. slot that into the pi and power it on
4. on the pi (either via ssh or locally) `sudo nixos-rebuild switch --flake github:jali-clarke/homelab-config#${configuration_name}`
    * if the pi runs out of memory and the process is killed, simply rerun the command and it will continue from where it left off (continue to rerun until done)
    * can also run from a host that knows how to build `aarch64-linux` and use `--build-host` + `--target-host`
5. logout and then log back in, or reboot
6. see relevant `manual steps` for the chosen configuration

### upgrading

if you want to see which version of a flake is installed, you can do `system_flake_version` and it will print out the versioned flake URI.  this includes the system's hostname and the revision hash of the flake source, as well as the date of that revision.

once installed, the above configurations will automatically use their own hostname with the configurations when installing; you need only do `sudo nixos-rebuild switch --flake github:jali-clarke/homelab-config/${ref}`, where `ref` is optional but if provided can be a `tag`, `commit` sha, `branch`, etc.  usually no reboot is necessary after but if the kernel is upgraded or something you should probably reboot to make sure all is well (rolling back if not).

## configurations

all ips below are made static in our router instead of in code for my own convenience.  all configurations, including [bootstrap images](#bootstrap-images), have `ssh` access with username `pi`.

### [atlas](./configurations/atlas)

* `x86_64-linux` server
* `192.168.0.103`
* fileserver exporting `nfs` and `smb` (`samba`) shares backed by `zfs` with auto-snapshotting via `sanoid`, replicated to [weedle](#weedle) via `syncoid`
* eventually setup email notifications out of `zed`
* `pihole` dns + other dnsmasq config
* `nexus` artifact hosting for container images and other artifacts

#### manual steps

all to be performed on `atlas` unless specified otherwise

1. do `sudo smbpasswd -a pi` and set a password in order to setup the `pi` `samba` user
2. as `pi`, run `load_ssh_key` with `SECRETS_PASSPHRASE` set to the appropriate value

### [bootstrap-bill](./configurations/bootstrap-bill)

* `x86_64-linux` [bootstrap image](#bootstrap-images)
* supports emulation of `aarch64-linux` binaries

### [nixos-oblivion](./configurations/nixos-oblivion)

* `x86_64-linux` vm hosted on windows desktop
* no fixed address
* useful when there are no other `x86_64-linux` environments available, e.g. rebuilding everything from scratch and i need to produce [bootstrap images](#bootstrap-images)

#### manual steps

all to be performed on `nixos-oblivion` unless specified otherwise

1. as `pi`, run `load_ssh_key` with `SECRETS_PASSPHRASE` set to the appropriate value

### [pi-baker](./configurations/pi-baker)

* `aarch64-linux` [bootstrap image](#bootstrap-images)
* intended for raspberry pi 3s

### [speet](./configurations/speet)

* `aarch64-linux` server
* `192.168.0.101`
* `aarch64-linux` k8s worker - can join k8s cluster simply with `join_cluster`

#### manual steps

all to be performed on `speet` unless specified otherwise

1. as `pi`, run `load_ssh_key` with `SECRETS_PASSPHRASE` set to the appropriate value
2. join the cluster with `join_cluster`

### [weedle](./configurations/weedle)

* `x86_64-linux` server
* `192.168.0.102`
* k8s master and `x86_64-linux` k8s worker (i know that having the master be a worker is against best practices, don't @ me)
* receives zfs backup snapshots from [atlas](#atlas) via `syncoid`
* eventually setup email notifications out of `zed`

#### manual steps

all to be performed on `weedle` unless specified otherwise

1. as `pi`, run `load_ssh_key` with `SECRETS_PASSPHRASE` set to the appropriate value
2. as `pi`, `ln -s /etc/kubernetes/cluster-admin.kubeconfig ~/.kube/config` (may need to fiddle with permissions somewhere)
