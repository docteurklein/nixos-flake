{ withSystem, inputs, ... }: {
  flake.nixosConfigurations."florian-desktop" = withSystem "x86_64-linux" (ctx@{ self', config, inputs', system, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        ../nixosModules/florian-desktop.nix
      ];
    }
  );
}