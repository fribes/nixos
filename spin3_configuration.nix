{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "spin3"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    publish = {
      enable = true;
      workstation = true;
      addresses = true;
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.groups.plugdev = {};

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.fribes = {
    isNormalUser = true;
    description = "fribes";
    extraGroups = [ "networkmanager" "wheel" "docker" "plugdev" "dialout"];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "fribes";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    bat
    btop
    curl
    dconf-editor
    diff-so-fancy
    direnv
    fd
    file
    fldigi
    fzf
    git
    gnomeExtensions.astra-monitor
    gnomeExtensions.workspace-matrix
    gnupg
    imhex
    keepassxc
    meld
    minicom
    ncdu
    neofetch
    ripgrep
    starship
    stow
    terminator
    usbutils
    vlc
    vim-full                   # full for clipboard support
    wget
    wine
    wsjtx
    yazi
    zathura
    zoxide
  ];

  environment.gnome.excludePackages = (with pkgs; [
    atomix # puzzle game
    cheese # webcam tool
    epiphany # web browser
    evince # document viewer
    geary # email reader
    gedit # text editor
    gnome-characters
    gnome-music
    gnome-photos
    gnome-terminal
    gnome-tour
    hitori # sudoku game
    iagno # go game
    tali # poker game
    totem # video player
  ]);

  fonts.packages = [
           pkgs.nerd-fonts._0xproto
           pkgs.nerd-fonts.droid-sans-mono
         ];

  programs.bash.interactiveShellInit = ''
      eval "$(fzf --bash)"
      eval "$(starship init bash)"
      eval "$(zoxide init bash)"
      eval "$(direnv hook bash)"
    '';

  programs.firefox.policies = {
      ExtensionSettings = with builtins;
        let extension = shortId: uuid: {
          name = uuid;
          value = {
            install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
            installation_mode = "normal_installed";
          };
        };
        in listToAttrs [
          (extension "ublock-origin" "uBlock0@raymondhill.net")
        ];
        # To add additional extensions, find it on addons.mozilla.org, find
        # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
        # Then, download the XPI by filling it in to the install_url template, unzip it,
        # run `jq .browser_specific_settings.gecko.id manifest.json` or
        # `jq .applications.gecko.id manifest.json` to get the UUID
  };

  services.fwupd.enable = true;

  services.flatpak.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="8087", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1d6b", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3754", MODE="660", GROUP="plugdev", TAG+="uaccess"
    '';

  environment.shellAliases = {
    grep="grep --color=auto";
    l="ls -CF";
    la="ls -A";
    ll="ls -alF";
    ls="ls --color=auto";
    sdrangel="flatpak run org.sdrangel.SDRangel";
    gp300="wine '.wine/drive_c/Program Files/Motorola/Professional GP300 GM300 CPS/R03.11.16_EN/gp300.exe'";
   };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
