{ config, pkgs, ... }:
{
  home.username = "Florian-Klein";
  home.homeDirectory = "/home/Florian-Klein";
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;
  programs.fish.enable = true;
  programs.helix = {
    enable = true;
    languages = {
      language = [{
        name = "rust";
        auto-format = false;
      }];
    };
  };
  programs.alacritty.enable = true;
  # wayland.windowManager.sway = {
  #   enable = true;
  #   config = rec {
  #     modifier = "Mod4";
  #     terminal = "fish"; 
  #     startup = [
  #     ];
  #   };
  # };
}