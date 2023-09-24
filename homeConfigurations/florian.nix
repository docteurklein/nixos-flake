{ withSystem, inputs, ... }: {
  flake.homeConfigurations."Florian-Klein" = withSystem "x86_64-linux" (ctx@{ pkgs, ... }:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ../home.nix ];
    }
  );
}
