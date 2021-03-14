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

  environment.systemPackages = [
    pkgs.git
    pkgs.vim
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };

    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
