# SSH Client Configuration
#
# Features:
# - Declarative SSH config file (~/.ssh/config) generation
# - Platform-aware settings (macOS keychain integration)
# - Global host settings (Host *)
#
# Platform Handling:
# - Linux: AddKeysToAgent, IdentitiesOnly, SetEnv, UseRoaming
# - macOS: All of the above + UseKeychain (macOS Keychain integration)
#
# Usage:
#   Automatically imported via common module
#   Override per-host if needed:
#     programs.ssh.matchBlocks."example.com" = {
#       hostname = "example.com";
#       user = "myuser";
#     };
{
  lib,
  pkgs,
  ...
}: {
  programs.ssh = {
    enable = true;

    # Global settings for all hosts (Host *)
    matchBlocks."*" = {
      extraOptions = lib.mkMerge [
        # Settings for all platforms
        {
          AddKeysToAgent = "yes";
          IdentitiesOnly = "yes";
          SetEnv = "TERM=xterm-256color";
          UseRoaming = "no";
        }
        # macOS-specific setting
        (lib.mkIf pkgs.stdenv.isDarwin {
          UseKeychain = "yes";
        })
      ];
    };
  };
}
