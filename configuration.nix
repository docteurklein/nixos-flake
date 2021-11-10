{ config, pkgs, ... }: {

  imports = [
    ./services/nixos-auto-update.nix
  ];

  fileSystems."/" = { options = [ "noatime" "nodiratime" ]; };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      grub = {
        enable = true;
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
    useDHCP = true;
    hostName = "florian-desktop";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 2022 ];
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
    nixos-auto-update.enable = false;
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
      ports = [ 2022 ];
    };
    xserver = {
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

  };

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
      packages = with pkgs; [
        firefox-bin
        alacritty
        docker-compose
      ];
    };
  };

  programs = {
    ssh.startAgent = false;
    vim.defaultEditor = true;
    fish.enable = true;
  };

  environment = {
    pathsToLink = ["/libexec"];
    systemPackages = with pkgs; [
      git
      inotify-tools
      binutils
      gnutls
      wget
      curl
      bind
      mkpasswd
      cachix
      tmux
      dmidecode
      vim
      socat
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
    };
  };

  nixpkgs = {
    config = {
      allowBroken = true;
      allowUnfree = true;
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
    /*    binaryCaches = [
      "https://matrix.cachix.org"
      ];
      binaryCachePublicKeys = [
      "matrix.cachix.org-1:h2ZM1LtvJBQhCb7a2Z/UpO8PKKIUlIvifvrFKfnHkro="
      ];*/
  };
  system = {
    stateVersion = "21.05"; # Did you read the comment?
    autoUpgrade = {
      enable = false;
      allowReboot = true;
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
