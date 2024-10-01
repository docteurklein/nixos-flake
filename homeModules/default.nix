{ config, lib, pkgs, ... }: {
  home.stateVersion = "23.05";
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "Florian Klein";
    userEmail = "florian.klein@free.fr";
  };
  programs.firefox = {
    enable = true;
    profiles.main = {
      isDefault = true;
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        darkreader
        privacy-badger
        multi-account-containers
        decentraleyes
        # https-everywhere
        # bitwarden
        # clearurls
        # duckduckgo-privacy-essentials
        # floccus
        # ghostery
        # languagetool
        # disconnect
      ];
      settings = {
        # "browser.startup.homepage" = "https://nixos.org";
        "browser.search.region" = "GB";
        "browser.search.isUS" = false;
        "distribution.searchplugins.defaultLocale" = "en-GB";
        "general.useragent.locale" = "en-GB";
        "browser.bookmarks.showMobileBookmarks" = true;
        "browser.newtabpage.pinned" = [{
          title = "NixOS";
          url = "https://nixos.org";
        }];
      };
      search = {
        default = "DuckDuckGo";
        force = true;
        engines = {
          "Nix Packages" = {
            icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                { name = "type"; value = "packages"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];
            definedAliases = [ "np!" ];
          };
          "Nix Options" = {
            icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            urls = [{
              template = "https://search.nixos.org/options";
              params = [
                { name = "type"; value = "options"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];
            definedAliases = [ "no!" ];
          };
          "NixOS Wiki" = {
            urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
            iconUpdateURL = "https://nixos.wiki/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000; # every day
            definedAliases = [ "@nw" ];
          };
          "Bing".metaData.hidden = true;
          "Google".metaData.alias = "g!";
        };
      };
    };
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
      gl = "git log";
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
    settings = {
      editor = {
        completion-trigger-len = 0;
        completion-replace = false;
        cursorline = true;
        cursorcolumn = true;
        true-color = true;
        undercurl = true;
        color-modes = true;
        cursor-shape = {
          insert = "bar";
          select = "underline";
        };
      };
      keys.insert.j = {
        j = "normal_mode"; # Maps `jj` to exit insert mode
      };
      keys.normal = {
        space.F = "file_picker_in_current_buffer_directory";
      };
    };
    languages = {
      language-server.phpactor = {
        command = "phpactor";
        args = [ "language-server" ];
      };
      language = [
        {
          name = "rust";
          auto-format = false;
        }
        {
          name = "php";
          language-servers = [ "phpactor" ];
        }
      ];
    };
  };
  home.sessionVariables = {
    EDITOR = "hx";
    LESS = "-SRXFi";
  };
  programs.alacritty.enable = true;

  programs.i3status-rust = {
    enable = true;
    bars = {
      top = {
        blocks = [
          {
            block = "net";
            device = "enp4s0";
          }
          {
            block = "disk_space";
            path = "/";
            info_type = "available";
            interval = 60;
            warning = 20.0;
            alert = 10.0;
          }
          {
            block = "memory";
            format = "$icon $mem_used_percents";
          }
          {
            block = "cpu";
            interval = 1;
          }
          {
            block = "load";
            interval = 1;
            format = "$icon $1m";
          }
          {
            block = "sound";
            click = [
              {
                button = "left";
                cmd = "pavucontrol --tab=3";
              }
            ];
          }
          {
            block = "time";
            interval = 5;
            format = "$timestamp.datetime(f:'%a %d/%m %T')";
          }
        ];
        settings = {
          theme = {
            theme = "solarized-dark";
            overrides = {
              idle_bg = "#123456";
              idle_fg = "#abcdef";
            };
          };
        };
        icons = "awesome5";
        theme = "gruvbox-dark";
      };
    };
  };

  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      output = [
        "DP-3"
      ];
      modules-right = [ "cpu" "memory" "disk" "network#dl" "network#ul" "temperature" "clock#date" "clock#time" ];

      disk = {
        format = "{percentage_used}%";
      };
      "network#dl" = {
        format = "DL: {bandwidthDownBytes}";
      };
      "network#ul" = {
        format = "UL: {bandwidthUpBytes}";
      };
      "clock#date" = {
        format = "{:%a %d/%m}";
      };
    };
  };

  programs.niri.settings = {
    input.keyboard.xkb = {
      layout  = "fr";
      variant = "bepo";
      # options "grp:win_space_toggle,compose:ralt,ctrl:nocaps"
    };
    outputs."edP-1" = {
      scale = 2.0;
    };
    binds = {
      "Mod+D".action.spawn = "rofi";
      "Mod+Shift+Q".action.quit.skip-confirmation = true;
    };
  };
  programs.rofi.enable = true;
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
    KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";
    GTK_THEME = "Materia-Dark";
  };

  # home.packages = with pkgs; [
  # ];
}
