{
  description = "env for managing bare metal infra";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware";
  inputs.homelab-secrets.url = "git+ssh://git@github.com/jali-clarke/homelab-secrets";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = flakeInputs@{ self, nixpkgs, nixos-hardware, homelab-secrets, flake-utils }:
    let
      overlay = hostname:
        import ./overlay {
          inherit hostname;
          selfSourceInfo = self.sourceInfo;
        };

      mkPkgs = { system, hostname, extraPkgsConfig ? { }, extraOverlays ? [ ] }:
        import nixpkgs {
          inherit system;
          config = extraPkgsConfig;
          overlays = [
            (overlay hostname)
          ] ++ extraOverlays;
        };
    in
    {
      nixosConfigurations =
        let
          nixosSystemFromDir =
            { system, subdirName, configurationFile ? "configuration.nix", extraPkgsConfig ? { }, extraOverlays ? [ ] }:
            nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
              inherit system;
              pkgs = mkPkgs { inherit extraPkgsConfig extraOverlays system; hostname = subdirName; };

              specialArgs = {
                inherit flakeInputs;
                ciphertexts = homelab-secrets.defaultPackage.${system};
                nixos-hardware-modules = nixos-hardware.nixosModules;
              };

              modules = [
                homelab-secrets.nixosModule
                (./configurations + "/${subdirName}/${configurationFile}")
                ./modules
              ];
            };
        in
        {
          atlas = nixosSystemFromDir { system = "x86_64-linux"; subdirName = "atlas"; };
          bootstrap-bill = nixosSystemFromDir { system = "x86_64-linux"; subdirName = "bootstrap-bill"; };
          cerberus = nixosSystemFromDir { system = "x86_64-linux"; subdirName = "cerberus"; };
          nixos-oblivion = nixosSystemFromDir { system = "x86_64-linux"; subdirName = "nixos-oblivion"; };

          # kodi's netflix plugin requires 32-bit userspace
          osmc = nixosSystemFromDir rec {
            system = "aarch64-linux";
            subdirName = "osmc";
            extraPkgsConfig = { allowUnfree = true; };
            extraOverlays = [
              (
                final: prev: {
                  pkgsArm32 = mkPkgs {
                    inherit extraPkgsConfig;
                    hostname = subdirName;
                    system = "armv7l-linux";
                    extraOverlays = [ (import ./overlay/arm32Fixes.nix) ];
                  };
                }
              )
            ];
          };

          pi-baker = nixosSystemFromDir { system = "aarch64-linux"; subdirName = "pi-baker"; };
          speet = nixosSystemFromDir { system = "aarch64-linux"; subdirName = "speet"; };
          spoot = nixosSystemFromDir { system = "aarch64-linux"; subdirName = "spoot"; };
          weedle = nixosSystemFromDir { system = "x86_64-linux"; subdirName = "weedle"; };
        };
    } // flake-utils.lib.eachDefaultSystem (
      system: {
        overlays = final: prev:
          let
            pkgs = mkPkgs { inherit system; hostname = "<overlay>"; };
          in
          {
            inherit (pkgs) k9s kubectl nixos-generators;
          };

        devShell =
          let
            pkgs = mkPkgs { inherit system; hostname = "<devShell>"; };
            meta = import ./lib/get-meta.nix { inherit pkgs; };

            terraform = pkgs.terraform.withPlugins (
              ps: [
                ps.cloudflare
                ps.hcloud
                ps.vault
              ]
            );

            kubectl = "${pkgs.kubectl}/bin/kubectl";
            nixos-generate = "${pkgs.nixos-generators}/bin/nixos-generate";
            ssh = "${pkgs.openssh}/bin/ssh";

            buildBootstrapBill = pkgs.writeScriptBin "build_bootstrap_bill" ''
              #!${pkgs.runtimeShell} -xe
              ${nixos-generate} -f install-iso --flake '.#bootstrap-bill'
            '';

            buildPiBaker = pkgs.writeScriptBin "build_pi_baker" ''
              #!${pkgs.runtimeShell} -xe
              ${nixos-generate} -f sd-aarch64-installer --flake '.#pi-baker'
            '';

            buildConfig = pkgs.writeScriptBin "build_config" ''
              #!${pkgs.runtimeShell} -xe
              ${pkgs.nixos-rebuild}/bin/nixos-rebuild build --flake ".#$1"
            '';

            fetchKubeconfig = pkgs.writeScriptBin "fetch_kubeconfig" ''
              #!${pkgs.runtimeShell} -e

              cat_remote_file () {
                ${ssh} pi@${meta.weedle.networkIP} -- sudo cat "$1"
              }

              ${kubectl} config set-cluster homelab --server=https://weedle

              ${kubectl} config set-cluster homelab --embed-certs \
                --certificate-authority=<(cat_remote_file /var/lib/kubernetes/secrets/ca.pem)

              ${kubectl} config set-credentials homelab-admin --embed-certs \
                --client-certificate=<(cat_remote_file /var/lib/kubernetes/secrets/cluster-admin.pem)

              ${kubectl} config set-credentials homelab-admin --embed-certs \
                --client-key=<(cat_remote_file /var/lib/kubernetes/secrets/cluster-admin-key.pem)

              ${kubectl} config set-context homelab --cluster=homelab --user=homelab-admin
            '';
          in
          pkgs.mkShell {
            name = "bare-metal-shell";
            buildInputs = [
              pkgs.diffutils
              pkgs.dnsutils
              pkgs.git
              pkgs.inetutils
              pkgs.k9s
              pkgs.kubectl
              pkgs.kubernetes-helm
              pkgs.nixos-generators
              pkgs.nixpkgs-fmt
              pkgs.openssl
              pkgs.qemu
              terraform
              pkgs.vim
              pkgs.wireguard-tools

              buildBootstrapBill
              buildPiBaker
              buildConfig
              fetchKubeconfig
            ];
          };
      }
    );
}
