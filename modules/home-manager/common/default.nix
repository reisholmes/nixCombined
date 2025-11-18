{
  lib,
  nixgl,
  outputs,
  pkgs,
  userConfig,
  ...
}: {
  # Packages that require configuration get placed in relevant place
  imports = [
    ../programs/atuin
    ../programs/fastfetch
    ../programs/fzf
    ../programs/kitty
    ../programs/lazygit
    ../programs/lf
    ../programs/ghostty
    ../programs/nix-search-tv
    ../programs/zoxide
    ../programs/zsh
    #../scripts
  ];

  # NOTE: nixpkgs configuration is intentionally NOT here for darwin compatibility
  # When using home-manager with nix-darwin and useGlobalPkgs=true, setting nixpkgs
  # options here triggers warnings. Instead:
  # - Darwin: nixpkgs overlays/config are set at the system level (hosts/*/default.nix)
  # - Linux: nixpkgs overlays/config are set in each home config (home/*/*/default.nix)

  # Home-Manager configuration for the user's home environment
  home = {
    username = "${userConfig.name}";
    homeDirectory =
      if pkgs.stdenv.isDarwin
      then "/Users/${userConfig.name}"
      else "/home/${userConfig.name}";

    file = {
      # oh-my-posh - custom theme file
      ohmyposhTheme = {
        source = ../assets/oh-my-posh/catppuccin.omp.json;
        target =
          if pkgs.stdenv.isDarwin
          then "/Users/${userConfig.name}/catppuccin.omp.json"
          else "/home/${userConfig.name}/catppuccin.omp.json";
      };
    };

    # declare our editor
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  # Ensure common packages are installed
  home.packages = with pkgs;
    [
      # Packages that don't require configuring
      bat
      btop
      claude-code
      dig
      duf
      eza
      fd
      gh
      git
      htop
      inetutils
      jq
      lsd
      neovim
      oh-my-posh
      pipenv
      python3
      ripgrep
      tldr
      tree
      wget
      yq
    ]
    ++ lib.optionals stdenv.isDarwin [
      mas
    ]
    ++ lib.optionals (!stdenv.isDarwin) [
      # Fonts for stylix to apply on Linux
      # On darwin, fonts are managed at system level via fonts.packages
      # Kitty overrides this in its config for Hack
      ibm-plex

      # Terminal fonts
      # https://github.com/nix-community/home-manager/issues/6160
      # If experiencing issues on linux run
      #    nix shell 'nixpkgs#fontconfig"
      #    fc-cache -vr
      nerd-fonts.hack
      nerd-fonts.jetbrains-mono

      # Emoji support
      noto-fonts-color-emoji

      # Linux-specific packages
      libreoffice-fresh
      ferdium
      filezilla
      flameshot
      magnetic-catppuccin-gtk
      protonvpn-gui
      rclone
      unzip
      wl-clipboard
      vlc
    ];

  # NOTE: Stylix configuration is intentionally NOT here
  # Stylix is configured in each home config (home/*/*/default.nix) to:
  # - Prevent config duplication
  # - Allow platform-specific theming (wallpapers, etc)
}
