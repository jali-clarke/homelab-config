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
          speet = nixosSystemFromDir {system = "aarch64-linux"; subdirName = "speet";};
          speet-installer = nixosSystemFromDir {system = "aarch64-linux"; subdirName = "speet"; configurationFile = "installer-configuration.nix";};
          weedle = nixosSystemFromDir {system = "x86_64-linux"; subdirName = "weedle";};
        };

      devShell.x86_64-linux =
        let
          pkgs = mkPkgs "x86_64-linux";
        in pkgs.mkShell {
          name = "bare-metal-shell";
          buildInputs = [
            pkgs.git
            pkgs.kubectl
            pkgs.nixos-generators
            pkgs.vim
          ];
        };
    };
}
