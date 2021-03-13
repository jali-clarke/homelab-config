{pkgs, ...}:
{
  networking.wireless.enable = false;  # Enables wireless support via wpa_supplicant.
  networking.firewall.enable = false;

  services.openssh.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  # stupid proxy since ad-hoc nfs mounts are really fiddly for some reason
  fileSystems."/.DUMMY_NFS_MOUNT" = {
    device = "FAKE_HOST:FAKE_PATH";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
  };

  environment.etc."docker/daemon.json".text = ''
    {
      "insecure-registries": ["docker.lan:5000"],
      "max-concurrent-uploads": 1
    }
  '';
}

