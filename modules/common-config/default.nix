{ pkgs, ... }:
let
  maxOpenFiles = toString (1024 * 1024);
in
{
  networking.wireless.enable = false; # Enables wireless support via wpa_supplicant.
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
    pkgs.dnsutils
    pkgs.htop
    pkgs.git
    pkgs.lsof
    pkgs.nmon
    pkgs.pv
    pkgs.rsync
    pkgs.vim
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };

    package = pkgs.nixFlakes;

    trustedUsers = [ "root" "pi" ];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  systemd.extraConfig = "LimitNOFILE=${maxOpenFiles}";

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = maxOpenFiles;
    }

    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = maxOpenFiles;
    }
  ];
}
