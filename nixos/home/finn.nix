{ config, pkgs, ... }:

{
  home.username = "finn";
  home.homeDirectory = "/home/finn";
  home.stateVersion = "24.11";

  # ============================================================================
  # Packages
  # Mapped from your Arch allowlists. Everything below is available in nixpkgs.
  # ============================================================================
  home.packages = with pkgs; [
    # Hyprland / Wayland ecosystem
    hyprpaper
    hyprcursor
    mako
    wofi
    fuzzel
    grim
    slurp
    wl-clipboard
    cliphist
    swayidle
    playerctl
    pamixer
    pavucontrol
    bluetui
    waybar
    ags

    # Terminal & Shell
    kitty
    fish
    starship
    neovim
    lf
    ncdu
    ripgrep
    tree-sitter
    gitui
    gh
    htop
    fastfetch

    # Browsers & Comms
    chromium
    telegram-desktop
    signal-desktop
    discord

    # Dev tools
    zig
    nodejs
    nodePackages.npm
    nodePackages.typescript
    python3
    docker-compose
    buildkit
    gjs

    # File manager
    nautilus

    # Fonts
    noto-fonts
    dejavu_fonts
    jetbrains-mono
    font-awesome

    # Misc
    cabextract
    os-prober
    sshfs
  ];

  # ============================================================================
  # Dotfiles (symlinked into place)
  # These files live in ~/.config/nixos/home/dotfiles/ and are tracked by git.
  # ============================================================================
  home.file = {
    ".bashrc".source = ./dotfiles/.bashrc;
    ".bash_profile".source = ./dotfiles/.bash_profile;
    ".gitconfig".source = ./dotfiles/.gitconfig;
  };

  # ============================================================================
  # Programs managed by Home Manager
  # ============================================================================

  # Git (complements the .gitconfig we symlink)
  programs.git = {
    enable = true;
    package = pkgs.git;
  };

  # Fish shell
  programs.fish = {
    enable = true;
    shellInit = ''
      # Add custom paths
      fish_add_path $HOME/.local/bin
      fish_add_path $HOME/.npm-global/bin
      fish_add_path $HOME/.opencode/bin
    '';
  };

  # Neovim (Home Manager installs it; your init.lua is in ~/.config/nvim/ from git)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Kitty terminal
  programs.kitty = {
    enable = true;
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  # ============================================================================
  # Services managed by Home Manager
  # ============================================================================
  services.mako = {
    enable = true;
  };

  # ============================================================================
  # Session / Autostart
  # ============================================================================
  # Hyprland autostart is handled by your ~/.config/hypr/hyprland.conf from git.
  # The .bash_profile we symlink also handles TTY1 -> Hyprland auto-login.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
