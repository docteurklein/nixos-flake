{ inputs, config, osConfig, lib, pkgs, ... }: {

  config = {
    age = {
      identityPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];
      secrets.email.file = ../secrets/email.age;
    };

    home.stateVersion = "23.05"; # keep to lowest possible to prove BC
    programs.home-manager.enable = true;

    # programs.git.iniContent."sendemail.free".smtpUser = lib.mkForce "florian.klein";
    programs.git = {
      enable = true;
      settings = {
        user.name = "Florian Klein";
        user.email = "florian.klein@free.fr";
        init.defaultBranch = "main";
      };
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.aerc = {
      enable = true;
      extraConfig.general.unsafe-accounts-conf = true;
    };

    accounts.email.accounts.free = {
      realName = "Florian Klein";
      userName = "florian.klein";
      passwordCommand = "cat /run/user/1000/agenix/email";
      address = "florian.klein@free.fr";
      # neomutt.mailboxType = "imap";
      aerc.enable = true;
      primary = true;
      smtp = {
        host = "smtp.free.fr";
        port = 465;
        tls.enable = true;
      };
      imap = {
        host = "imap.free.fr";
        port = 993;
        tls.enable = true;
      };
    };

    programs.librewolf = {
      enable = true;
      profiles.main = {
        isDefault = true;
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          sponsorblock
          ublock-origin
          darkreader
          # privacy-badger
          multi-account-containers
          # decentraleyes
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
          default = "ddg";
          force = true;
          engines = {
            "openstreetmap" = {
              urls = [{
                template = "https://www.openstreetmap.org/search";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              definedAliases = [ "omap!" ];
            };
            "googlemaps" = {
              urls = [{
                template = "https://www.google.com/maps";
                params = [
                  { name = "q"; value = "{searchTerms}"; }
                ];
              }];
              definedAliases = [ "map!" ];
            };
            "postgres" = {
              urls = [{
                template = "https://www.postgresql.org/search/";
                params = [
                  { name = "u"; value = "/docs/18"; }
                  { name = "q"; value = "{searchTerms}"; }
                ];
              }];
              definedAliases = [ "ps!" ];
            };
            "Nix Packages" = {
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
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
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
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
              icon = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "nw!" ];
            };
            "bing".metaData.hidden = true;
            "google".metaData.alias = "g!";
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
        us = "systemctl --user";
        j = "sudo journalctl";
        uj = "journalctl --user";
        d = "docker";
        dc = "docker compose";
        dr = "docker run --rm it";
        dcr = "docker compose run --rm";
        dce = "docker compose exec";
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
          end-of-line-diagnostics = "hint";
          inline-diagnostics = {
            cursor-line = "error";
          };
          lsp = {
            display-messages = true;
          };
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
          continue-comments = false;
        };
        keys.insert.j = {
          j = "normal_mode"; # Maps `jj` to exit insert mode
        };
        keys.normal = {
          space.F = "file_picker_in_current_buffer_directory";
        };
      };
      languages = {
        language-server = {
          phpactor = {
            command = "phpactor";
            args = [ "language-server" ];
          };
          rust-analyzer.config = {
            check.command = "clippy";
          };
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

    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings.mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        # output = [
        #   "DP-3"
        # ];
        modules-right = [ "cpu" "temperature" "memory" "disk" "battery" "network" "network#dl" "network#ul" "clock#date" "clock#time" ];

        cpu = {
          format = "cpu: {usage}% load: {load}";
        };
        battery = {
          format = "battery: {capacity}%";
        };
        memory = {
          format = "memory: {percentage}%";
        };
        disk = {
          format = "disk used: {percentage_used}%";
        };
        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
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

    systemd.user.services."xwayland-satellite" = {
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Unit = {
        Description = "xwayland-satellite sidecar service after niri starts";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
        Restart = "on-failure";
      };
    };

    programs.niri.settings = {
      environment = {
          DISPLAY = ":0";
      };
      input.keyboard = {
        repeat-delay = 200;
        repeat-rate = 60;
      };
      input.touchpad = {
        natural-scroll = true;
      };
      outputs."edP-1" = {
        # scale = 2.0;
      };
      binds = {
        "Mod+D".action.spawn = "fuzzel";
        "Mod+Q".action.close-window = {};
        # "Mod+Shift+Q".action.quit = true;
        "XF86AudioRaiseVolume" = {
          allow-when-locked = true;
          action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+" ];
        };
        "XF86AudioLowerVolume" = {
          allow-when-locked = true;
          action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"];
        };
        "XF86AudioMute" = {
          allow-when-locked = true;
          action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
        };
        "XF86AudioMicMute" = {
          allow-when-locked = true;
          action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ];
        };
        "Mod+Left".action.focus-column-left = {};
        "Mod+Down".action.focus-window-or-workspace-down = {};
        "Mod+Up".action.focus-window-or-workspace-up = {};
        "Mod+Right".action.focus-column-right = {};

        "Mod+Ctrl+Left".action.move-column-left = {};
        "Mod+Ctrl+Down".action.move-window-down-or-to-workspace-down = {};
        "Mod+Ctrl+Up".action.move-window-up-or-to-workspace-up = {};
        "Mod+Ctrl+Right".action.move-column-right = {};

        "Mod+Tab".action.focus-workspace-previous = {};

        "Mod+Comma".action.consume-window-into-column = {};
        "Mod+Shift+Comma".action.expel-window-from-column = {};

        "Mod+R".action.switch-preset-column-width = {};
        "Mod+F".action.maximize-column = {};
        "Mod+Shift+F".action.fullscreen-window = {};
        "Mod+C".action.center-column = {};

        "Mod+Minus".action.set-column-width = "-10%";
        "Mod+Equal".action.set-column-width = "+10%";

        "Mod+Space".action.toggle-overview = {};

        "Print".action.screenshot = {};
        "Ctrl+Print".action.screenshot-screen = {};
        "Alt+Print".action.screenshot-window = {};
      };
    };

    programs.fuzzel = {
      enable = true;
    };

    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        # package = pkgs.gnome.gnome-themes-extra;
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
        gtk-theme = "Adwaita-dark";
        enable-hot-corners = false;
      };
    };
    home.sessionVariables = {
      GTK_THEME = "Adwaita:dark";
    };

    # home.packages = with pkgs; [
    # ];
  };
}
