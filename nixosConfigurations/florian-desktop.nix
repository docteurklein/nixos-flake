{ withSystem, inputs, self', ... }: {
  flake.nixosConfigurations."florian-desktop" = withSystem "x86_64-linux" (ctx@{ self', config, inputs', system, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        inputs.nur.nixosModules.nur
        inputs.home-manager.nixosModules.home-manager
        inputs.disko.nixosModules.disko
        inputs.nix-snapshotter.nixosModules.default
        ../nixosModules/florian-desktop.nix
      ];
    }
  );
}
