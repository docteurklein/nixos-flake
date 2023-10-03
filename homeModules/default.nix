{ config, lib, pkgs, ... }: {
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "Florian Klein";
    userEmail = "florian.klein@free.fr";
  };
  programs.fish = {
    enable = true;
    shellAliases = {
      n = "nix";
      ll = "ls -Alh";
      s = "sudo systemctl";
      j = "sudo journalctl";
      d = "docker";
      dc = "docker-compose";
      dr = "docker run --rm it";
      dcr = "docker-compose run --rm";
      dce = "docker-compose exec";
      v = "vim";
      g = "git";
      gc = "git commit";
      gd = "git diff";
      gds = "git diff --staged";
      gs = "git status";
      gr = "git restore";
      gpl = "git pull";
      gpr = "git pull --rebase";
      grs = "git restore --staged";
      gph = "git push --force-with-lease";
      k = "kubectl";
      kg = "kubectl get";
      kd = "kubectl describe";
      ke = "kubectl exec -it";
      kl = "kubectl logs --tail=1 -f";
      ks = "kubectl config set-context --current --namespace";
    };
  };
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    historyLimit = 50000;
    extraConfig = builtins.readFile ../dotfiles/tmux.conf;
  };
  programs.helix = {
    enable = true;
    languages = {
      language = [{
        name = "rust";
        auto-format = false;
      }];
    };
  };
  home.sessionVariables = {
    EDITOR = "hx";
    LESS = "-SRXFi";
  };
  programs.alacritty.enable = true;

  xsession.windowManager.i3 = {
    enable = true;
    # config = {
    #   # modifier = "Mod4";
    #   bars = [];
    # };
  };
  xdg.configFile."i3/config".source = lib.mkForce ../dotfiles/i3.conf;
  
  # wayland.windowManager.sway = {
  #   enable = true;
  #   config = rec {
  #     modifier = "Mod4";
  #     terminal = "fish"; 
  #     startup = [
  #     ];
  #   };
  # };
  gtk = {
    enable = true;
    theme = {
      name = "Materia-dark";
      package = pkgs.materia-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
    };
  };
  home.sessionVariables = {
    # KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";
    GTK_THEME = "Materia-Dark";
  };
}