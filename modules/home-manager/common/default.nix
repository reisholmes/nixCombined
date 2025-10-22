{
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
    ../programs/ghostty
    ../programs/nix-search-tv
    ../programs/zoxide
    ../programs/zsh
    #../scripts
  ];

  # Nixpkgs configuration
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
    ];

    config = {
      allowUnfree = true;
    };
  };

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
      deskflow
      dig
      duf
      eza
      fd
      ferdium
      filezilla
      git
      htop
      inetutils
      jq
      lf
      neovim
      oh-my-posh
      pipenv
      python3
      ripgrep
      tldr
      tree
      vlc
      wget
      yq

      # Fonts for stylix to apply
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
    ]
    ++ lib.optionals stdenv.isDarwin [
      mas
    ]
    ++ lib.optionals (!stdenv.isDarwin) [
      flameshot
      magnetic-catppuccin-gtk
      unzip
      wl-clipboard
    ];

  # Theme support from stylix
  stylix = {
    autoEnable = true;
    enable = true;

    # disable the theme for specific apps
    targets = {
      lazygit = {
        enable = false;
      };
      ghostty = {
        enable = false;
      };
      gtk = {
        enable = false;
      };
      kde = {
        enable = false;
      };
      kitty = {
        enable = false;
      };
    };

    # theme, list at https://github.com/tinted-theming/schemes
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # fonts https://stylix.danth.me/configuration.html#fonts
    fonts = {
      serif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Serif";
      };

      sansSerif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Sans";
      };

      monospace = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
