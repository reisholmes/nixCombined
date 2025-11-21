{
  lib,
  pkgs,
  userConfig,
  ...
}: {
  programs.git = {
    enable = true;

    # Default user name from userConfig (can be overridden per-host)
    userName = lib.mkDefault userConfig.fullName;
    # Email is set per-host since it varies by context

    # Git settings (new format)
    settings = {
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
}
