{
  description = "env for managing bare metal infra";

  # testing PR https://github.com/NixOS/nixpkgs/pull/140165
  # revert back to updated github:NixOS/nixpkgs once ^ is merged
  inputs.nixpkgs.url = "github:jali-clarke/nixpkgs/jali-clarke/nexus-3.32.0-03";
  inputs.nixos-generators.url = "github:nix-community/nixos-generators";

  inputs.agenix.url = "github:ryantm/agenix";
  inputs.agenix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, nixos-generators, agenix }:
    let
      overlay = { system, hostname }:
        import ./overlay {
          inherit hostname;
          nixos-generators = nixos-generators.defaultPackage.${system};
          selfSourceInfo = self.sourceInfo;
        };

      mkPkgs = { system, hostname }:
        import nixpkgs {
          inherit system;
          overlays = [
            agenix.overlay
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
              modules = [
                agenix.nixosModules.age
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

            ${ssh} -i /run/secrets/id_rsa_nixops pi@${meta.weedle.networkIP} -- sudo cat /etc/kubernetes/cluster-admin.kubeconfig > ~/.kube/config
            ${ssh} -i /run/secrets/id_rsa_nixops pi@${meta.weedle.networkIP} -- sudo cat /var/lib/kubernetes/secrets/ca.pem > /var/lib/kubernetes/secrets/ca.pem
            ${ssh} -i /run/secrets/id_rsa_nixops pi@${meta.weedle.networkIP} -- sudo cat /var/lib/kubernetes/secrets/cluster-admin.pem > /var/lib/kubernetes/secrets/cluster-admin.pem
            ${ssh} -i /run/secrets/id_rsa_nixops pi@${meta.weedle.networkIP} -- sudo cat /var/lib/kubernetes/secrets/cluster-admin-key.pem > /var/lib/kubernetes/secrets/cluster-admin-key.pem
          '';
        in
        pkgs.mkShell {
          name = "bare-metal-shell";
          buildInputs = [
            pkgs.agenix
            pkgs.git
            pkgs.kubectl
            pkgs.nixos-generators
            pkgs.nixpkgs-fmt
            pkgs.vim

            buildBootstrapBill
            buildPiBaker
            fetchKubeconfig
          ];
        };

      devShell.x86_64-darwin =
        let
          pkgs = mkPkgs { system = "x86_64-darwin"; hostname = "<devShell>"; };
        in
        pkgs.mkShell {
          name = "bare-metal-shell";
          buildInputs = [
            pkgs.agenix
            pkgs.nixpkgs-fmt
          ];
        };
    };
}
