{ config, pkgs, lib, ciphertexts, ... }:
let
  wireguardPort = 51820;

  secretFilePi = secretFilePath: {
    file = secretFilePath;
    owner = "pi";
  };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  age.secrets = {
    id_cerberus = secretFilePi ciphertexts."id_cerberus.age";
    "id_cerberus.pub" = secretFilePi ciphertexts."id_cerberus.pub.age";
    "id_dev_env.pub" = secretFilePi ciphertexts."id_dev_env.pub.age";
    "wg_server_key".file = ciphertexts."wg_server_key.age";
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip6 main {
        chain input {
          # drop all incoming ipv6 traffic by default
          type filter hook input priority filter; policy drop;

          # accept any packets coming from established connections that originated from this machine
          ct state {established, related} accept

          # accept anything coming from localhost
          iifname lo accept
        }

        chain output {
          # allow all outgoing connections
          type filter hook output priority filter; policy accept;
        }

        chain forward {
          # disable forwarding
          type filter hook forward priority filter; policy drop;
        }
      }

      table ip main {
        set routable_subnets {
          type ipv4_addr
          flags interval
          elements = {192.168.0.0/24, 192.168.128.0/24}
        }

        chain input {
          # drop all incoming traffic by default
          type filter hook input priority filter; policy drop;

          # accept any packets coming from established connections that originated from this machine
          ct state {established, related} accept

          # accept anything coming from localhost
          iifname lo accept

          # accept ping on all interfaces
          icmp type echo-request accept

          # accept ssh from wan
          iifname eth0 tcp dport 22 accept

          # accept wireguard tunnel from wan
          iifname eth0 udp dport ${builtins.toString wireguardPort} accept
        }

        chain output {
          # allow all outgoing connections
          type filter hook output priority filter; policy accept;
        }

        chain forward {
          # disable forwarding by default
          type filter hook forward priority filter; policy drop;

          # allow outgoing for wan as gateway
          oifname eth0 ip saddr @routable_subnets accept

          # allow incoming for established wan connections
          iifname eth0 ct state {established, related} accept

          # allow traffic within / between routable subnets
          iifname wg-homelab oifname wg-homelab ip saddr @routable_subnets ip daddr @routable_subnets accept
        }

        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;

          # masquerade outgoing traffic for eth0 as wan gatway
          oifname eth0 ip saddr @routable_subnets masquerade
        }
      }
    '';
  };

  homelab-config.users = {
    allowPasswordAuth = false;
    authorizedKeyPaths = [
      config.age.secrets."id_dev_env.pub".path
    ];

    authorizedKeysExtraActivationDeps = [ "agenix" ];
  };

  networking.hostName = "cerberus";

  networking.wireguard = {
    enable = true;
    interfaces.wg-homelab = {
      ips = [ "192.168.128.1/24" ];
      listenPort = wireguardPort;
      privateKeyFile = config.age.secrets."wg_server_key".path;

      peers = [
        {
          # client gateway
          publicKey = "uvG7qleIRUR7+ekAF/znMwGqqxsWHPKzJ6VjFrWoq20=";
          allowedIPs = [ "192.168.128.2/32" "192.168.0.0/24" ];
        }
        {
          # my phone
          publicKey = "gaowMC14zZPk8hjK2N3GRXb6QyeGWaRvyyunlT4cYnw=";
          allowedIPs = [ "192.168.128.101/32" ];
        }
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
