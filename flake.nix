{
  description = "env for managing bare metal infra";

  outputs = { self, nixpkgs }: {
    devShell.x86_64-linux =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.mkShell {
        name = "bare-metal-shell";
        buildInputs = [
          pkgs.nixos-generators
          pkgs.kubectl
        ];
      };
  };
}
