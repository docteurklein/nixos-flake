{ config, pkgs, lib, ... }: {

  imports = [
  ];

  fileSystems."/" = { options = [ "noatime" "nodiratime" ]; };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      grub = {
        enable = true;
        configurationLimit = 10;
        version = 2;
        efiSupport = false;
        enableCryptodisk = true;
        device = "/dev/sdb";
      };
    };
    initrd.luks.devices = {
      crypt = {
        device = "/dev/sdb2";
        preLVM = true;
      };
    };
  };

  networking = {
    hostName = "florian-desktop";
    useDHCP = false;
    interfaces.enp3s0.useDHCP = true;
    enableIPv6 = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 22 8080 8081 ];
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
    keyMap = "fr-bepo";
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      powerline-fonts
    ];
  };

  services = {
    #nixos-auto-update.enable = false;
    logrotate = {
      enable = true;
      extraConfig = ''
        compress
        create
        daily
        dateext
        delaycompress
        missingok
        notifempty
        rotate 31
      '';
    };
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
      forwardX11 = true;
      ports = [ 22 ];
    };
    xserver = {
        videoDrivers = [ "nvidia" ];
        enable = true;
        desktopManager = {
            xterm.enable = false;
        };
        displayManager = {
            defaultSession = "none+i3";
        };
        windowManager.i3 = {
            enable = true;
            extraPackages = with pkgs; [
                rofi
                i3status
                i3blocks
            ];
        };
        layout = "fr";
        xkbVariant = "bepo";
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    
      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      extraPlugins = [
        #pkgs.pg_ivm
      ]; 
    };
  };

  hardware.opengl.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;

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
      extraConfig = builtins.readFile ./conf/tmux.conf;
    };
  };

  environment = {
    variables = {
      EDITOR = "vim";
    };
    pathsToLink = ["/libexec"];
    systemPackages = with pkgs; [
      git
      inotify-tools
      binutils
      gnutls
      gnumake
      firefox-bin
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
      ((vim_configurable.override { python = python3; }).customize {
        name = "vim";
        vimrcConfig = {
          customRC = builtins.readFile ./conf/vimrc;
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
      google-cloud-sdk
      kubectl
      kubectx
      k9s
      xdot
      graphviz
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
      grs = "git restore --staged";
      k = "kubectl";
      kg = "kubectl get";
      kd = "kubectl describe";
      kl = "kubectl logs --tail=1 -f";
      ks = "kubectl config set-context --current --namespace";
    };
  };

  nixpkgs = {
    config = {
      allowBroken = true;
      allowUnfree = true;
      packageOverrides = pkgs: with pkgs; {
        #pg_ivm = pkgs.callPackage ./pg_ivm.nix {};
      };
    };
  };

  nix = {
    package = pkgs.nixFlakes;
    useSandbox = true;
    autoOptimiseStore = true;
    readOnlyStore = false;
    allowedUsers = [ "@wheel" ];
    trustedUsers = [ "@wheel" ];
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
    stateVersion = "21.11"; # Did you read the comment?
    autoUpgrade = {
      enable = false;
      allowReboot = false;
      flake = "github:docteurklein/nixos-flake";
      flags = [
        "--recreate-lock-file"
        "--no-write-lock-file"
        "-L" # print build logs
      ];
      dates = "daily";
    };
  };
}
