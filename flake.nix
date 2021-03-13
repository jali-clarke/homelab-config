{
  description = "env for managing bare metal infra";

  outputs = {self, nixpkgs}: {
    nixosConfigurations =
      let
        nixosSystemFromDir =
          {system, subdirName}:
          nixpkgs.lib.nixosSystem {
            inherit system;
            modules = ["${./configurations}/${subdirName}/configuration.nix"];
          };
      in
      {
        atlas = nixosSystemFromDir {system = "x86_64-linux"; subdirName = "atlas";};
        bootstrap-bill = nixosSystemFromDir {system = "x86_64-linux"; subdirName = "bootstrap-bill";};
        nixos-oblivion = nixosSystemFromDir {system = "x86_64-linux"; subdirName = "nixos-oblivion";};
        speet = nixosSystemFromDir {system = "aarch64-linux"; subdirName = "speet";};
        weedle = nixosSystemFromDir {system = "x86_64-linux"; subdirName = "weedle";};
      };

    devShell.x86_64-linux =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
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
