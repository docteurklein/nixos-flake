{ withSystem, inputs, self', ... }:
{
  flake.homeConfigurations."Florian-Klein" = withSystem "x86_64-linux" (ctx@{ pkgs, ... }:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../homeModules/default.nix
        ({...}: {
          nixpkgs.overlays = [ inputs.nur.overlay ];
          home.username = "Florian-Klein";
          home.homeDirectory = "/home/Florian-Klein";
        })
      ];
    }
  );
  flake.homeConfigurations."florian" = withSystem "x86_64-linux" (ctx@{ pkgs, ... }:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../homeModules/default.nix
        ({...}: {
          nixpkgs.overlays = [ inputs.nur.overlay ];
          home.username = "florian";
          home.homeDirectory = "/home/florian";
        })
      ];
    }
  );
}
