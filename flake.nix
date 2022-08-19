{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    pgx.url = "github:tcdi/pgx";
  };

  outputs = { nixpkgs, pgx, ... }: {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ config, pkgs, ... }:
            {
              nixpkgs.overlays = [pgx.overlay];
              nix = {
                binaryCaches = [
                  "https://cache.nixos.org"
                  "https://nix-community.cachix.org"
                ];
                binaryCachePublicKeys = [
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
              };

              imports =
                [
                  ./hardware-configuration.nix
                  ./configuration.nix
                ];
            }
          )
          #home-manager.nixosModules.home-manager
          #{
          #  home-manager.useGlobalPkgs = true;
          #  home-manager.useUserPackages = true;
          #}
        ];
      };
    };
  };
}
