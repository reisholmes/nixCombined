_: {
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;

    # Default behavior: provides 'z' and 'zi' commands
    # Regular 'cd' usage is still tracked for building the directory database
  };
}
