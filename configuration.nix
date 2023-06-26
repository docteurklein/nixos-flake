{ config, pkgs, lib, ... }: {
  boot = {
    readOnlyNixStore = false;
    kernelParams = [ "boot.shell_on_fail" ]; 
    kernelPackages = pkgs.linuxPackages;
    #kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      grub = {
        enable = true;
        configurationLimit = 10;
        enableCryptodisk = true;
      };
    };
    extraModulePackages = [ ];
    kernelModules = [ "dm-snapshot" ];
    initrd.kernelModules = [ "dm-snapshot" ];
    initrd.availableKernelModules = [ ];
  };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=20s
    DefaultTimeoutStartSec=20s
  '';

  networking = {
    useDHCP = false;
    enableIPv6 = true;
    firewall = {
      enable = false;
      allowedTCPPorts = [ 80 443 22 8080 8081 6443 ];
      allowedUDPPorts = [ 53 ];
      allowPing = true;
    };
  };

  time.timeZone = "Europe/Paris";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  };

  console = {
    font = "Lat2-Terminus16";
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      powerline-fonts
    ];
  };

  services = {
    logrotate = {
      enable = true;
    };
    journald.extraConfig = ''
      MaxRetentionSec=7day
      RateLimitInterval=10s
      RateLimitBurst=100000
    '';
    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
      ports = [ 22 ];
    };
    xserver = {
        enable = true;
        desktopManager = {
            xterm.enable = false;
        };
        displayManager = {
          defaultSession = "none+i3";
          autoLogin = {
            enable = true;
            user = "florian";
          };
          sessionCommands = ''
            ${pkgs.xorg.xset}/bin/xset r rate 190 80
          '';
        };
        windowManager.i3 = {
            enable = true;
            extraPackages = with pkgs; [
                rofi
                i3status
                i3lock
                i3blocks
            ];
        };
        autoRepeatDelay = 190;
        autoRepeatInterval = 80;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
      extraPlugins = with pkgs.postgresql15Packages; [
        wal2json
        pg_ivm
        pg_hint_plan
      ];
      settings = {
        log_connections = true;
        log_statement = "all";
        logging_collector = true;
        log_disconnections = true;
        log_destination = lib.mkForce "syslog";
        wal_level = "logical";
        #"auto_explain.log_nested_statements" = true;
        #"auto_explain.log_min_duration" = 0;
        shared_preload_libraries = "auto_explain,pg_hint_plan,pg_stat_statements";
        max_connections = 100;
        shared_buffers = "3GB"; # 1/4th of RAM
        work_mem = "30MB"; # 1/4th of RAM / max_connections
        effective_cache_size = "9GB"; # 75% of total RAM
        maintenance_work_mem = "1GB";
        checkpoint_completion_target = 0.9;
        wal_buffers = "16MB";
        default_statistics_target = 100;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
        min_wal_size = "1GB";
        max_wal_size = "4GB";
        max_worker_processes = 6;
        max_parallel_workers_per_gather = 3;
        max_parallel_workers = 6;
        max_parallel_maintenance_workers = 3;
      };
    };
  };
  services.k3s.enable = true;

  systemd.services.postgresql.serviceConfig = {
    MemoryMax = "12G";
  };

  hardware.opengl.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
      enableOnBoot = true;
    };
  };

  security = {
    rtkit.enable = true;
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  users = {
    mutableUsers = false;
    users.florian = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" ];
      shell = pkgs.fish;
      uid = 1000;
      # mkpasswd -m sha-512 password
      hashedPassword = "$6$Qxe1C3WtH06$Tl9DzDcMqtuhASktIm.raH/cICBkcquiBYhB./ZhmC6S6IeBmT3uhIBX6dNNXa46GQJDt9hhHF1sCy25fAnfD.";
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNFd+owyL4UYCZM9PqJnl2Z6SMeBQQmZdi09tXCTgzLxWL1LnLyB45GoDLSt9PWkcy8+Dhk3SU1JRI32rwXdpPSCGXYETLvrxGKyZ7ySxl+tdVcdOawOvb5MC3+258SDK8b2Fz0pDCZAUl8NYyDv27efO4m2JH27DWoCOMk3DezAk+itLzNeRh61LJd/9+H7ZvqyXDjSdS12GlfVGs4MFAALq5zZXX76dh4Xs21XC6IwZK7Dq8NE0WARJT8OL8IT+tTcs0qoQDNBd+eb4Llxe7pRcnM/Pd9Wo0ceKGdjfIiOKRaFN6Q7WzI+l+fVdHa4vFHQVxOOydmD2F0jVIzXoT florian@florian"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICYjyOT9I0Tpr72BeMjQbq7aP0Pj+octMDI5yDnn/BKy"
      ];
      packages = with pkgs; [
      ];
    };
  };
  documentation = {
    man.enable = false;
  };
  programs = {
    steam.enable = true;
    ssh.startAgent = false;
    fish.enable = true;
    tmux = {
      enable = true;
      keyMode = "vi";
      historyLimit = 50000;
      extraConfig = builtins.readFile ./dotfiles/tmux.conf;
    };
  };

  environment = {
    variables = {
      EDITOR = "vim";
      LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
      LESS = "-SRXFi";
    };
    pathsToLink = [
      "/libexec"
      "/share/nix-direnv"
    ];
    systemPackages = with pkgs; [
      man
      sway
      iftop
      jq
      htop
      direnv
      nix-direnv
      git
      inotify-tools
      binutils
      gnutls
      gnumake
      firefox
      stremio
      alacritty
      docker-compose
      gcc
      wget
      curl
      bind
      mkpasswd
      cachix
      tmux
      dmidecode
      helix
      ((vim_configurable.override { }).customize {
        name = "vim";
        vimrcConfig = {
          customRC = builtins.readFile ./dotfiles/vimrc;
        };
        vimrcConfig.packages.myVimPackage = with vimPlugins; {
          start = [
            jellybeans-vim
            vim-airline
            fugitive
            ctrlp-vim
            tabular
            vim-surround
            vim-lsp
            fzf-vim
          ];
        };
      })
      fd
      ripgrep
      socat
      (google-cloud-sdk.withExtraComponents ([google-cloud-sdk.components.gke-gcloud-auth-plugin]))
      kubectl
      kubectx
      kubernetes-helm
      k9s
      xdot
      graphviz
      libclang.lib
      pavucontrol
      pulseaudio-ctl
      vlc
    ];

    shellAliases = {
      s = "sudo systemctl";
      j = "sudo journalctl";
      d = "docker";
      dc = "docker-compose";
      dr = "docker run --rm it";
      dcr = "docker-compose run --rm";
      dce = "docker-compose exec --rm";
      v = "vim";
      g = "git";
      gc = "git commit";
      gd = "git diff";
      gs = "git status";
      gr = "git restore";
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

  nixpkgs = {
    overlays = [
      (self: super: {
        nix-direnv = super.nix-direnv.override { enableFlakes = true; };
      })
    ];
    config = {
      allowBroken = true;
      allowUnfree = true;
      packageOverrides = pkgs: with pkgs; {
      };
    };
  };

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
    package = pkgs.nixFlakes;

    settings = {
      max-jobs = lib.mkDefault 4;
      sandbox = true;
      trusted-users = [ "@wheel" ];
      allowed-users = [ "@wheel" ];
      auto-optimise-store = true;
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d --max-freed $((64 * 1024**3))";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  system = {
    stateVersion = "22.11"; # Did you read the comment?
    autoUpgrade = {
      enable = true;
      allowReboot = false;
      flake = "/etc/nixos";
      flags = [
        "--recreate-lock-file"
        "-L" # print build logs
      ];
      dates = "weekly";
    };
  };
}
