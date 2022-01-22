{
  description = "env for managing bare metal infra";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/535c1e5a72e1bf15b71ed1a59de84a9ae7a0eb91";
  inputs.homelab-secrets.url = "git+ssh://git@github.com/jali-clarke/homelab-secrets";

  outputs = { self, nixpkgs, homelab-secrets }:
    let
      overlay = { system, hostname }:
        import ./overlay {
          inherit hostname;
          selfSourceInfo = self.sourceInfo;
        };

      mkPkgs = { system, hostname }:
        import nixpkgs {
          inherit system;
          overlays = [
            (overlay { inherit system hostname; })
          ];
        };
    in
    {
      nixosConfigurations =
        let
          nixosSystemFromDir =
            { system, subdirName, configurationFile ? "configuration.nix" }:
            nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
              inherit system;
              pkgs = mkPkgs { inherit system; hostname = subdirName; };
              specialArgs.ciphertexts = homelab-secrets.defaultPackage.${system};
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
          nixos-oblivion = nixosSystemFromDir { system = "x86_64-linux"; subdirName = "nixos-oblivion"; };
          pi-baker = nixosSystemFromDir { system = "aarch64-linux"; subdirName = "pi-baker"; };
          speet = nixosSystemFromDir { system = "aarch64-linux"; subdirName = "speet"; };
          weedle = nixosSystemFromDir { system = "x86_64-linux"; subdirName = "weedle"; };
        };

      overlays.x86_64-linux = final: prev:
        let
          pkgs = mkPkgs { system = "x86_64-linux"; hostname = "<overlay>"; };
        in
        {
          inherit (pkgs) k9s kubectl nixos-generators;
        };

      devShell.x86_64-linux =
        let
          pkgs = mkPkgs { system = "x86_64-linux"; hostname = "<devShell>"; };
          meta = import ./lib/get-meta.nix { inherit pkgs; };

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

          fetchKubeconfig = pkgs.writeScriptBin "fetch_kubeconfig" ''
            #!${pkgs.runtimeShell} -e
            mkdir -p ~/.kube /var/lib/kubernetes/secrets
            mkdir -p /var/lib/kubernetes/secrets

            for target_file in ~/.kube/config /var/lib/kubernetes/secrets/ca.pem /var/lib/kubernetes/secrets/cluster-admin.pem /var/lib/kubernetes/secrets/cluster-admin-key.pem; do
              if [ -e $target_file ]; then
                echo warning! $target_file already exists, moving to $target_file.old
                mv $target_file $target_file.old
              fi
            done

            ${ssh} pi@${meta.weedle.networkIP} -- sudo cat /etc/kubernetes/cluster-admin.kubeconfig > ~/.kube/config
            ${ssh} pi@${meta.weedle.networkIP} -- sudo cat /var/lib/kubernetes/secrets/ca.pem > /var/lib/kubernetes/secrets/ca.pem
            ${ssh} pi@${meta.weedle.networkIP} -- sudo cat /var/lib/kubernetes/secrets/cluster-admin.pem > /var/lib/kubernetes/secrets/cluster-admin.pem
            ${ssh} pi@${meta.weedle.networkIP} -- sudo cat /var/lib/kubernetes/secrets/cluster-admin-key.pem > /var/lib/kubernetes/secrets/cluster-admin-key.pem
          '';

          updateKnownGood = pkgs.writeScriptBin "update_known_good" ''
            #!${pkgs.runtimeShell} -e

            for tag in $(${pkgs.git}/bin/git tag | ${pkgs.gnugrep}/bin/grep known-good); do
              ${pkgs.git}/bin/git tag -f $tag $1
            done

            ${pkgs.git}/bin/git push -f --tag
          '';
        in
        pkgs.mkShell {
          name = "bare-metal-shell";
          buildInputs = [
            pkgs.diffutils
            pkgs.dnsutils
            pkgs.git
            pkgs.kubectl
            pkgs.kubernetes-helm
            pkgs.nixos-generators
            pkgs.nixpkgs-fmt
            pkgs.openssl
            pkgs.telnet
            pkgs.vim

            buildBootstrapBill
            buildPiBaker
            fetchKubeconfig
            updateKnownGood
          ];
        };

      devShell.x86_64-darwin =
        let
          pkgs = mkPkgs { system = "x86_64-darwin"; hostname = "<devShell>"; };
        in
        pkgs.mkShell {
          name = "bare-metal-shell";
          buildInputs = [
            pkgs.nixpkgs-fmt
          ];
        };
    };
}
