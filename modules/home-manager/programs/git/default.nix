_: {
  programs.git = {
    enable = true;

    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = false;
      };
    };

    # Enable delta for better diff viewing
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
      };
    };
  };

  # Note: userName and userEmail should be configured locally via:
  # git config --global user.name "Your Name"
  # git config --global user.email "your.email@example.com"
}
