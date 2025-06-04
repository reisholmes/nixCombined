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
    ../programs/k9s
    ../programs/kitty
    ../programs/lazygit
    ../programs/ghostty
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
      (azure-cli.withExtensions [azure-cli.extensions.aks-preview])
      bat
      btop
      deskflow
      dig
      duf
      eza
      fd
      ferdium
      filezilla
      fluxcd
      git
      go
      htop
      inetutils
      jq
      kubectl
      kubelogin
      lf
      neovim
      oh-my-posh
      pipenv
      powershell
      python3
      ripgrep
      terraform
      tldr
      tree
      vlc
      wget
      yamllint
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

      # NVIM specific requirements
      ######
      # markdown conform requirement
      markdownlint-cli2

      # nix lsp requirements
      alejandra
      nixd

      # Terraform lsp, linter
      terraform-ls
      # also used in pre-commit
      tflint

      # pre-commit requirements
      # hgttps://github.com/antonbabenko/pre-commit-terraform
      checkov
      pre-commit
      terraform-docs
      terragrunt
    ]
    ++ lib.optionals stdenv.isDarwin [
      #colima
      #docker
      #hidden-bar
      #raycast
      mas
    ]
    ++ lib.optionals (!stdenv.isDarwin) [
      # controls sound
      #pavucontrol
      #pulseaudio
      #tesseract
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
