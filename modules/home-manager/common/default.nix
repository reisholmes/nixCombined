# Common Home Manager Configuration
#
# This module provides base configuration imported by all systems including:
# - Core CLI tools (git, fzf, zsh, ripgrep, bat, etc.)
# - NixGL support for non-NixOS graphics acceleration
# - Stylix theming framework integration
# - Common program configurations (kitty, ghostty, lazygit, etc.)
#
# Usage:
#   Import in host configs with: "${nhModules}/common"
#
# Platform Support:
#   - Linux (NixOS and non-NixOS with home-manager standalone)
#   - macOS (nix-darwin with home-manager module)
#
# Dependencies:
#   - Requires nhModules path injected via extraSpecialArgs
#   - Requires userConfig for user-specific settings (name, email, etc.)
#   - Platform detection via pkgs.stdenv.isDarwin
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
      # Test tealdeer 1.7.2 to see if SSL works
      tealdeer =
        if super.stdenv.isDarwin
        then
          (import (builtins.fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/e6f23dc08d3624daab7094b701aa3954923c6bbb.tar.gz";
            sha256 = "0m0xmk8sjb5gv2pq7s8w7qxf7qggqsd3rxzv3xrqkhfimy2x7bnx";
          }) {system = super.stdenv.system;}).tealdeer
        else super.tealdeer;
    })
  ];
  # Packages that require configuration get placed in relevant place
  imports = [
    # Common modules
    ./nixgl-profiles.nix
    ./nixgl-wrapper.nix
    ./nixpkgs-config.nix
    ./stylix-common.nix
    ./stylix-host.nix

    # Custom utility scripts
    ../scripts

    # Program configurations
    ../programs/atuin
    ../programs/fastfetch
    ../programs/fzf
    ../programs/ghostty
    ../programs/git
    ../programs/kitty
    ../programs/lazygit
    ../programs/lf
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
      # oh-my-posh - nix packages parser script
      nixPackagesScript = {
        source = ../assets/oh-my-posh/nix-packages.sh;
        target = ".config/oh-my-posh/nix-packages.sh";
        executable = true;
      };
    };

    # declare our editor
    sessionVariables =
      {
        EDITOR = "nvim";
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        # Fix SSL certificates for Nix packages on macOS
        NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
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
      tree
      wget
      yq
    ]
    ++ lib.optionals stdenv.isDarwin [
      claude-code
      mas
      tealdeer
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
      tealdeer
      unzip
      vlc
      wl-clipboard
    ];

  # NOTE: Stylix configuration is intentionally NOT here
  # Stylix is configured in each home config (home/*/*/default.nix) to:
  # - Prevent config duplication
  # - Allow platform-specific theming (wallpapers, etc)
}
