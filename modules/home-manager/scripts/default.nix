# Custom Utility Scripts
#
# Installs custom scripts to ~/.local/bin
# Scripts are automatically available in PATH
#
# Available Scripts:
# - fif: Find in files (interactive grep with fzf)
# - fkill: Kill processes interactively with fzf
# - pull-all: Update all git repositories in a directory
#
# Usage:
#   Automatically imported via common module
#   Scripts available in PATH after home-manager switch
{
  lib,
  pkgs,
  ...
}: {
  home.file.".local/bin" = {
    source = ./bin;
    recursive = true;
  };

  # Ensure scripts are executable
  home.activation.makeScriptsExecutable = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run find $HOME/.local/bin -type f -exec chmod +x {} \;
  '';

  # Add to PATH (especially important for macOS)
  # Note: On Linux, ~/.local/bin is typically already in default PATH
  # Darwin requires explicit PATH addition for user-installed scripts
  home.sessionPath = lib.mkIf pkgs.stdenv.isDarwin ["$HOME/.local/bin"];
}
