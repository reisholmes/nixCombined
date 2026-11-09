# What: Installs the custom scripts in this directory to ~/.local/bin.
# Used by: Imported by home-manager/common/default.nix.
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
  home.sessionPath = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ["$HOME/.local/bin"];
}
