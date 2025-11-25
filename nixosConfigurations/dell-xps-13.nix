{ withSystem, inputs, self', ... }: {
  flake.nixosConfigurations."dell-xps-13" = withSystem "x86_64-linux" (ctx@{ self', config, inputs', system, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        inputs.agenix.nixosModules.default
        inputs.nur.modules.nixos.default
        inputs.home-manager.nixosModules.home-manager
        inputs.disko.nixosModules.disko
        inputs.nix-snapshotter.nixosModules.default
        ../nixosModules/dell-xps-13.nix
      ];
    }
  );
}
