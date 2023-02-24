{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    #pgx.url = "github:tcdi/pgx";
  };

  outputs = { nixpkgs, ... }: {
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ config, pkgs, ... }:
            {
              #nixpkgs.overlays = [pgx.overlay];
              nix = {
                settings = {
                  substituters = [
                    "https://cache.nixos.org"
                    "https://nix-community.cachix.org"
                  ];
                  trusted-public-keys = [
                    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                  ];
                };
              };

              imports =
                [
                  ./configuration.nix
                ];
            }
          )
        ];
      };
    };
  };
}
