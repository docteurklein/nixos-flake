{ withSystem, inputs, self', ... }: {
  flake.nixosConfigurations."florian-desktop" = withSystem "x86_64-linux" (ctx@{ self', config, inputs', system, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ../nixosModules/florian-desktop.nix
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.florian = import ../homeModules/default.nix;
        }
      ];
    }
  );
}