# homelab-config

configuration as code for our homelab

## what / why

i've been in a number of situations where i had to do a rebuild of our homelab machines due to either disk failure, hardware upgrades, etc, and this is kind of annoying to do when your (brain) memory isn't amazing.  it's especially annoying when it isn't reproduceable.

enter the almighty [NixOS](https://nixos.org/) - an OS whose package manager and configuration language is [Nix](https://nixos.org/explore.html).  this allows us to declaratively define configuration for entire systems and even share / modularize configuration across systems.  with [nix flakes](https://nixos.wiki/wiki/Flakes), this becomes almost 100% reproduceable across time and machines.

### license

[MIT](https://opensource.org/licenses/MIT) with the following subtitutions made appropriately:
* my name (Jinnah Ali-Clarke)
* the date associated with whatever revision you are currently looking at

## how to use

### prerequisites

* `nix` with [flakes](https://nixos.wiki/wiki/Flakes) support
* an `x86_64-linux` system in order to build the [bootstrap images](#bootstrap-images)
* an internet connection on each machine that you plan to set up
* appropriate SSH key(s) to pull down the secrets repo

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
5. generate ssh host keys for the machine in the appropriate (mounted) dir, rekeying secrets in the secrets repo as necessary
6. copy the `hardware-configuration.nix` back to this repo into the configuration dir of your choice, reference it correctly in the corresponding `configuration.nix` and commit + push it.  delete both `hardware-configuration.nix` and `configuration.nix` from the machine but not this repo
7. on the machine (either via ssh or locally) `sudo nixos-install --no-root-passwd --flake github:jali-clarke/homelab-config#${configuration_name}`
8. reboot
9. see relevant `manual steps` (if any) for the chosen configuration

#### for `aarch64-linux` systems

for raspberry pis specifically

1. create the [pi-baker](#pi-baker) image by doing `build_pi_baker`
2. flash the resulting image to a micro sd card
3. slot that into the pi and power it on
4. generate ssh host keys for the pi in the appropriate dir, rekeying secrets in the secrets repo as necessary
5. on the pi (either via ssh or locally) `sudo nixos-rebuild switch --flake github:jali-clarke/homelab-config#${configuration_name}`
    * if the pi runs out of memory and the process is killed, simply rerun the command and it will continue from where it left off (continue to rerun until done)
    * can also run from a host that knows how to build `aarch64-linux` and use `--build-host` + `--target-host`
6. logout and then log back in, or reboot
7. see relevant `manual steps` (if any) for the chosen configuration

### upgrading

if you want to see which version of a flake is installed, you can do `system_flake_version --show` and it will print out the versioned flake URI.  this includes the system's hostname and the revision hash of the flake source, as well as the date of that revision.

once installed, the above configurations will automatically use their own hostname with the configurations when installing; you need only do `system_flake_version -i <key_path> --update <ref>`, where `ref` is optional but if provided can be a `tag`, `commit` sha, `branch`, etc.  usually no reboot is necessary after but if the kernel is upgraded or something you should probably reboot to make sure all is well (rolling back if not).

## configurations

all ips below are made static in our router instead of in code for my own convenience.  all configurations, including [bootstrap images](#bootstrap-images), have `ssh` access with username `pi`.

### [atlas](./configurations/atlas)

* `x86_64-linux` server
* `192.168.0.103`
* fileserver exporting `nfs` and `smb` (`samba`) shares backed by `zfs` with auto-snapshotting via `sanoid`, replicated to [weedle](#weedle) via `syncoid`
* email notifications out of `zed` on scrub and etc
* `pihole` dns + other dnsmasq config
* `nexus` artifact hosting for container images and other artifacts

#### manual steps

all to be performed on `atlas` unless specified otherwise

1. do `sudo smbpasswd -a pi` and set a password in order to setup the `pi` `samba` use

### [bootstrap-bill](./configurations/bootstrap-bill)

* `x86_64-linux` [bootstrap image](#bootstrap-images)
* supports emulation of `aarch64-linux` binaries

### [nixos-oblivion](./configurations/nixos-oblivion)

* `x86_64-linux` vm hosted on windows desktop
* no fixed address
* useful when there are no other `x86_64-linux` environments available, e.g. rebuilding everything from scratch and i need to produce [bootstrap images](#bootstrap-images)

### [osmc](./configurations/osmc)

* `aarch64-linux` server
* `192.168.0.104`
* not related to the OSMC distro, but definitely inspired by it.  replaces an old OSMC installation and wanted to keep the hostname

#### manual steps

all to be performed on `osmc` unless specified otherwise

1. once booted and logged in (automatically), you'll need to confirm that you want to use the addons installed and then config them.  might move more stuff to `advancedsettings.xml` to automate

### [pi-baker](./configurations/pi-baker)

* `aarch64-linux` [bootstrap image](#bootstrap-images)
* intended for raspberry pi 3s

### [speet](./configurations/speet)

* `aarch64-linux` server
* `192.168.0.101`
* `aarch64-linux` k8s worker - should automatically join cluster

#### manual steps

all to be performed on `speet` unless specified otherwise

1. ensure that the node has successfully joined the cluster upon system activation, e.g. `journalctl -eu kubernetes-auto-join-cluster.service`
    * if this fails, have a look at https://nixos.wiki/wiki/Kubernetes#Join_Cluster_not_working - you may need to restart `cfssl` on the cluster master and then re-run the `kubernetes-auto-join-cluster` service

### [weedle](./configurations/weedle)

* `x86_64-linux` server
* `192.168.0.102`
* k8s master and `x86_64-linux` k8s worker (i know that having the master be a worker is against best practices, don't @ me)
* receives zfs backup snapshots from [atlas](#atlas) via `syncoid`
* email notifications out of `zed` on scrub and etc

#### manual steps

all to be performed on `weedle` unless specified otherwise

1. as `pi`, `ln -s /etc/kubernetes/cluster-admin.kubeconfig ~/.kube/config` (may need to fiddle with permissions somewhere)

## k8s

this repo also contains [infrastructure-as-code](./k8s) for all the k8s services running on the cluster.  if you want to deploy from scratch, do the following:

1. make sure secrets are configured accordingly in vault
2. `nix develop` in the root of this repo
3. `kubectl apply -k k8s/argocd/overlay`
4. go to the `argocd` dashboard (probably `https://argocd.jali-clarke.ca`) and make sure it's alive and well
5. `kubectl apply -k k8s/applicationsets/basic-infrastructure`
6. back to the `argocd` dashboard to make sure everything's coming up
7. deploy everything else: `kubectl apply -k k8s/applicationsets/all-the-services`
8. back to the dashboard to make sure everything else is up

if you just want to deploy a change, start from step 5 or 7 as necessary instead of going all the way to the beginning
