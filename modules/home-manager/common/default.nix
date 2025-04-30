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
    ../programs/fzf
    ../programs/k9s
    ../programs/kitty
    ../programs/lazygit
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

  # Fixed nixGL package issues on Linux
  # e.g. Kitty won't run without this
  nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
    offloadWrapper = "mesaPrime";
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
      dig
      duf
      eza
      fd
      fluxcd
      git
      go
      htop
      jq
      kubectl
      kubelogin
      lf
      neofetch
      nvim
      oh-my-posh
      pipenv
      python3
      ripgrep
      terraform
      tldr
      tree
      wget
      yamllint
      yq

      # Terminal fonts
      # https://github.com/nix-community/home-manager/issues/6160
      # If experiencing issues on linux run
      #    nix shell 'nixpkgs#fontconfig"
      #    fc-cache -vr
      nerd-fonts.hack

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
      tflint
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
      unzip
      wl-clipboard
    ];

  # Catpuccin flavor and accent
  #  catppuccin = {
  #  flavor = "mocha";
  #  accent = "lavender";
  #};

  # Theme support from stylix
  stylix = {
    enable = true;

    # theme, list at https://github.com/tinted-theming/schemes
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # wallpaper https://stylix.danth.me/configuration.html#wallpaper
    image = ../assets/stylix/wallpaper_wave_mac.jpg;

    # fonts https://stylix.danth.me/configuration.html#fonts
    fonts = {
      serif = {
        package = pkgs.nerd-fonts.hack;
        name = "Hack Nerd Font Propo";
      };

      sansSerif = {
        package = pkgs.nerd-fonts.hack;
        name = "Hack Nerd Font Propo";
      };

      monospace = {
        package = pkgs.nerd-fonts.hack;
        name = "Hack Nerd Font Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
