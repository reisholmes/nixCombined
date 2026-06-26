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
  # Override python314 globally to skip tests for proton-core
  # See: https://github.com/ProtonVPN/python-proton-core/pull/10
  nixpkgs.overlays = [
    (_: super: {
      python314 = super.python314.override {
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
    ../programs/direnv
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
      # tealdeer config, used to stop ssl errors on macOS in 1.8.1
      # https://github.com/tealdeer-rs/tealdeer/issues/452
      tealdeerScript = {
        source = ../assets/tealdeer/config.toml;
        target = "Library/Application\ Support/tealdeer/config.toml";
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
      }
      // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
        # sudoedit runs nvim as the invoking user but with a reset environment
        # (sudo's env_reset strips/repoints HOME and XDG_*), so nvim can't find
        # ~/.config/nvim and falls back to no config. Restore the user's HOME
        # and XDG dirs so `sudoedit` loads our real nvim config and writes
        # state/cache to user-owned dirs. nvim still runs unprivileged here —
        # only sudoedit's file copy-back is elevated, so no privilege escalation.
        # Linux-only: the /home path and the env_reset behaviour are Linux
        # concerns; the Darwin home dir differs (/Users/<name>).
        SUDO_EDITOR = "/usr/bin/env HOME=/home/${userConfig.name} XDG_CONFIG_HOME=/home/${userConfig.name}/.config XDG_DATA_HOME=/home/${userConfig.name}/.local/share XDG_STATE_HOME=/home/${userConfig.name}/.local/state XDG_CACHE_HOME=/home/${userConfig.name}/.cache nvim";
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
      python314
      ripgrep
      tealdeer
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
      proton-vpn
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
