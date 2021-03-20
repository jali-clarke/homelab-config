{
  description = "env for managing bare metal infra";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.nixos-generators.url = "github:nix-community/nixos-generators";

  outputs = { self, nixpkgs, nixos-generators }:
    let
      overlay = system:
        final: prev: {
          nixos-generators = nixos-generators.defaultPackage.${system};
        };

      mkPkgs = system: import nixpkgs { inherit system; overlays = [ (overlay system) ]; };
    in
    {
      nixosConfigurations =
        let
          nixosSystemFromDir =
            { system, subdirName, configurationFile ? "configuration.nix" }:
            nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
              inherit system;
              pkgs = mkPkgs system;
              modules = [
                (./configurations + "/${subdirName}/${configurationFile}")
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
          pkgs = mkPkgs "x86_64-linux";
        in
        {
          inherit (pkgs) kubectl nixos-generators;
        };

      devShell.x86_64-linux =
        let
          pkgs = mkPkgs "x86_64-linux";
          meta = import ./lib/get-meta.nix {inherit pkgs;};

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

            ${ssh} -i ~/.ssh/id_rsa_nixops pi@${meta.weedle.networkIP} -- sudo cat /etc/kubernetes/cluster-admin.kubeconfig > ~/.kube/config
            ${ssh} -i ~/.ssh/id_rsa_nixops pi@${meta.weedle.networkIP} -- sudo cat /var/lib/kubernetes/secrets/ca.pem > /var/lib/kubernetes/secrets/ca.pem
            ${ssh} -i ~/.ssh/id_rsa_nixops pi@${meta.weedle.networkIP} -- sudo cat /var/lib/kubernetes/secrets/cluster-admin.pem > /var/lib/kubernetes/secrets/cluster-admin.pem
            ${ssh} -i ~/.ssh/id_rsa_nixops pi@${meta.weedle.networkIP} -- sudo cat /var/lib/kubernetes/secrets/cluster-admin-key.pem > /var/lib/kubernetes/secrets/cluster-admin-key.pem
          '';
        in
        pkgs.mkShell {
          name = "bare-metal-shell";
          buildInputs = [
            pkgs.ccrypt
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
          pkgs = mkPkgs "x86_64-darwin";
        in
        pkgs.mkShell {
          name = "bare-metal-shell";
          buildInputs = [
            pkgs.ccrypt
            pkgs.nixpkgs-fmt
          ];
        };
    };
}
