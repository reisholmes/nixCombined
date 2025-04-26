{
  outputs,
  userConfig,
  pkgs,
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

  # Home-Manager configuration for the user's home environment
  home = {
    username = "${userConfig.name}";
    homeDirectory =
      if pkgs.stdenv.isDarwin
      then "/Users/${userConfig.name}"
      else "/home/${userConfig.name}";

    # oh-my-posh - custom theme file
    file = {
      name =
        if pkgs.stdenv.isDarwin
        then "/Users/${userConfig.name}/catppuccin.omp.json"
        else "/home/${userConfig.name}/catppuccin.omp.json";
      source = ../assets/catppuccin.omp.json;
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
      mas
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
      nerd-fonts.hack

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
  catppuccin = {
    flavor = "mocha";
    accent = "lavender";
  };
}
