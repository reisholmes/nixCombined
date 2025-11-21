{
  lib,
  pkgs,
  userConfig,
  ...
}: {
  # Override python313 globally to skip tests for proton-core
  # See: https://github.com/ProtonVPN/python-proton-core/pull/10
  nixpkgs.overlays = [
    (_: super: {
      python313 = super.python313.override {
        packageOverrides = _: pysuper: {
          proton-core = pysuper.proton-core.overridePythonAttrs (_: {
            doCheck = false;
            doInstallCheck = false;
          });
        };
      };
    })
  ];
  # Packages that require configuration get placed in relevant place
  imports = [
    ./nixpkgs-config.nix
    ./stylix-common.nix
    ./nixgl-wrapper.nix
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
  ];

  # NOTE: nixpkgs configuration is now included via ./nixpkgs-config.nix
  # Since useGlobalPkgs is no longer used, home-manager can safely manage nixpkgs config on both Darwin and Linux

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
        target = "catppuccin.omp.json";
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
      nvd
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
      claude-code
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
      deskflow
      ferdium
      filezilla
      flameshot
      libreoffice-fresh
      magnetic-catppuccin-gtk
      protonvpn-gui
      rclone
      unzip
      vlc
      wl-clipboard
    ];

  # NOTE: Stylix configuration is intentionally NOT here
  # Stylix is configured in each home config (home/*/*/default.nix) to:
  # - Prevent config duplication
  # - Allow platform-specific theming (wallpapers, etc)
}
