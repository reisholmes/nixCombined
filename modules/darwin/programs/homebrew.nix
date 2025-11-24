# Homebrew Configuration Module for nix-darwin
#
# Purpose: Provides declarative Homebrew package management on macOS
#
# Features:
#   - Homebrew taps (third-party repositories)
#   - Brews (command-line tools)
#   - Casks (GUI applications)
#   - Mac App Store apps via mas
#   - Automatic cleanup of unmanaged packages
#
# Platform: macOS only (nix-darwin)
#
# Usage:
#   Import in your darwin host configuration:
#   imports = [ darwinModules.programs.homebrew ];
#
#   Then configure packages:
#   homebrew = {
#     enable = true;
#     brews = [ "package-name" ];
#     casks = [ "app-name" ];
#   };
#
# Documentation: https://mynixos.com/nix-darwin/options/homebrew
#
_: {
  homebrew = {
    enable = true;

    # Cleanup strategy: "uninstall" removes packages not in config
    # Alternative: "zap" (more aggressive, may remove shared files)
    onActivation.cleanup = "uninstall";

    # Homebrew taps (third-party repositories)
    # Format: "owner/repo"
    taps = [
      "deskflow/homebrew-tap"
      "hashicorp/tap"
      "jesseduffield/lazydocker"
      "powershell/tap"
    ];

    # Brews (command-line tools, typically pre-compiled binaries)
    brews = [
      "adr-tools"
      "awscli"
      "azure-cli"
      "lazydocker"
      "node"
      "podman"
    ];

    # Casks (macOS native GUI applications)
    # Managed via command line for declarative installs
    casks = [
      "deskflow"
      "gcloud-cli"
      "ghostty"
      "powershell"
      "proton-pass"
      # Raycast setup: https://www.youtube.com/watch?v=DBifQv9AYhc
      "raycast"
      # Remote desktop client
      "windows-app"
    ];

    # Mac App Store apps (requires being logged in)
    # Find app IDs with: mas search "app name"
    # List installed: mas list
    masApps = {
      # Example: "App Name" = 1234567890;
    };
  };
}
