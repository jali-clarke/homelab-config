{
  description = "env for managing bare metal infra";

  inputs.nixos-generators.url = "github:nix-community/nixos-generators";

  outputs = {self, nixpkgs, nixos-generators}:
    let
      overlay = system:
        final: prev: {
          nixos-generators = nixos-generators.defaultPackage.${system};
        };

      mkPkgs = system: import nixpkgs {inherit system; overlays = [(overlay system)];};
    in
    {
      nixosConfigurations =
        let
          nixosSystemFromDir =
            {system, subdirName, configurationFile ? "configuration.nix"}:
              nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
                inherit system;
                pkgs = mkPkgs system;
                modules = [
                  (./configurations + "/${subdirName}/${configurationFile}")
                ];
              };
        in
        {
          atlas = nixosSystemFromDir {system = "x86_64-linux"; subdirName = "atlas";};
          bootstrap-bill = nixosSystemFromDir {system = "x86_64-linux"; subdirName = "bootstrap-bill";};
          nixos-oblivion = nixosSystemFromDir {system = "x86_64-linux"; subdirName = "nixos-oblivion";};
          pi-baker = nixosSystemFromDir {system = "aarch64-linux"; subdirName = "pi-baker";};
          speet = nixosSystemFromDir {system = "aarch64-linux"; subdirName = "speet";};
          weedle = nixosSystemFromDir {system = "x86_64-linux"; subdirName = "weedle";};
        };

      devShell.x86_64-linux =
        let
          pkgs = mkPkgs "x86_64-linux";
          nixos-generate = "${pkgs.nixos-generators}/bin/nixos-generate";

          buildBootstrapBill = pkgs.writeScriptBin "build_bootstrap_bill" ''
            #!${pkgs.runtimeShell} -xe
            ${nixos-generate} -f install-iso --flake '.#bootstrap-bill'
          '';

          buildPiBaker = pkgs.writeScriptBin "build_pi_baker" ''
            #!${pkgs.runtimeShell} -xe
            ${nixos-generate} -f sd-aarch64-installer --flake '.#pi-baker'
          '';

        in pkgs.mkShell {
          name = "bare-metal-shell";
          buildInputs = [
            pkgs.git
            pkgs.kubectl
            pkgs.nixos-generators
            pkgs.vim

            buildBootstrapBill
            buildPiBaker
          ];
        };
    };
}
