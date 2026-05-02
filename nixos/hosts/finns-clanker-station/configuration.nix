{ config, pkgs, ... }:

{
  # ============================================================================
  # Boot & Loader
  # ============================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  # ============================================================================
  # LUKS Encryption
  # Replace the UUID with your actual LUKS partition UUID after generating
  # hardware-configuration.nix. This is just a template.
  # ============================================================================
  # boot.initrd.luks.devices."cryptroot" = {
  #   device = "/dev/disk/by-uuid=REPLACE-ME";
  #   preLVM = true;
  #   allowDiscards = true;  # TRIM support for SSDs
  # };

  # ============================================================================
  # Networking
  # ============================================================================
  networking.hostName = "finns-clanker-station";
  networking.networkmanager.enable = true;

  # ============================================================================
  # Locale & Time
  # ============================================================================
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # ============================================================================
  # Console / Keyboard
  # ============================================================================
  console.keyMap = "us";

  # ============================================================================
  # Users
  # ============================================================================
  users.users.finn = {
    isNormalUser = true;
    description = "Finn";
    initialPassword = "finn";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "docker" "audio" "video" ];
  };

  # Allow passwordless sudo for wheel group members (convenience for a single-user laptop)
  security.sudo.wheelNeedsPassword = false;

  # ============================================================================
  # System Packages
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Base tools
    git
    vim
    nano
    wget
    curl
    unzip
    man

    # Nix tools
    nixpkgs-fmt

    # Filesystem
    ntfs3g
    dosfstools
    mtools
  ];

  # ============================================================================
  # Hardware
  # ============================================================================
  hardware.enableAllFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # ============================================================================
  # Services
  # ============================================================================
  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Bluetooth
  services.blueman.enable = true;

  # Networking
  services.openssh.enable = false;  # Set to true if you need SSH access

  # Printing
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Docker
  virtualisation.docker.enable = true;

  # Flatpak (optional but useful)
  services.flatpak.enable = true;

  # ============================================================================
  # Desktop Environment
  # ============================================================================
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Fish
  programs.fish.enable = true;

  # ============================================================================
  # Nix Settings
  # ============================================================================
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # ============================================================================
  # System State Version (do not change unless you know what you're doing)
  # ============================================================================
  system.stateVersion = "24.11";
}
