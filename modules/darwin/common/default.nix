# Common Darwin (macOS) Configuration Module
#
# Purpose: Provides shared system-level configuration for all nix-darwin hosts
#
# Features:
#   - Nixpkgs configuration (allow unfree, overlays)
#   - Nix daemon settings (experimental features, garbage collection)
#   - System fonts installation
#   - TouchID for sudo authentication
#   - Automatic store optimization
#
# Platform: macOS only (nix-darwin)
#
# Usage:
#   Import in your darwin host configuration:
#   imports = [ darwinModules.common ];
#
# Dependencies:
#   - outputs: flake outputs for overlays
#   - pkgs: nixpkgs package set
#
{
  pkgs,
  outputs,
  ...
}: {
  # Nixpkgs configuration
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
    overlays = [
      outputs.overlays.stable-packages
    ];
  };

  # Nix daemon settings
  nix = {
    # Automatic garbage collection
    gc = {
      automatic = true;
      interval = [
        {
          Hour = 3;
          Minute = 15;
          Weekday = 7; # Sunday
        }
      ];
      options = "--delete-older-than 21d";
    };

    # Automatic store optimization (deduplicate identical files)
    optimise.automatic = true;

    package = pkgs.nix;

    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  # System fonts - Installed to /Library/Fonts/Nix Fonts
  fonts.packages = with pkgs; [
    ibm-plex
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji
  ];

  # Security - Enable TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
}
