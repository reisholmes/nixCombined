# What: Home-manager aspect enabling zoxide with zsh integration.
# Used by: Imported by home-manager/common/default.nix.
_: {
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;

    # Default behavior: provides 'z' and 'zi' commands
    # Regular 'cd' usage is still tracked for building the directory database
  };
}
