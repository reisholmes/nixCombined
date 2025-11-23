# Git Version Control Configuration
#
# Features:
# - User identity configuration (name, email) from userConfig
# - SSH commit signing support via ssh-signing.nix submodule
# - Delta diff viewer with git integration
# - GitHub CLI credential helper integration
#
# Platform Handling:
# - Works on both Linux and macOS
# - User name defaults to userConfig.fullName (can be overridden per-host)
# - Email typically set per-host due to work/personal contexts
#
# Submodules:
# - ssh-signing.nix: Declarative SSH commit signing configuration
#   Provides programs.git.sshSigning options for managing allowed signers
#
# Usage:
#   Automatically imported via common module
#   Configure per-host settings:
#     programs.git.settings.user.email = "your@email.com";
#     programs.git.sshSigning.enable = true;

{
  lib,
  pkgs,
  userConfig,
  ...
}: {
  imports = [
    ./ssh-signing.nix
  ];

  programs.git = {
    enable = true;

    # Git settings
    settings = {
      # Default user name from userConfig (can be overridden per-host)
      user.name = lib.mkDefault userConfig.fullName;
      # Email is set per-host since it varies by context

      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = false;
      };
      diff = {
        colorMoved = "dimmed-zebra";
      };

      # GitHub CLI credential helper
      credential = {
        "https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
        "https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      };
    };
  };

  # Delta - enhanced diff viewer with git integration
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
    };
  };
}
