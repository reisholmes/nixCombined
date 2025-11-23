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
