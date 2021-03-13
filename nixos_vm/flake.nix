{
  outputs = {self, nixpkgs}: {
    nixosConfigurations.nixos-oblivion = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [./configuration.nix];
    };
  };
}
