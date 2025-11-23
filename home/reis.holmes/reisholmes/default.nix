{
  config,
  pkgs,
  nhModules,
  inputs,
  userConfig,
  ...
}:
let
  # Personal email for personal repos
  personalEmail = "4367558+reisholmes@users.noreply.github.com";

  # Shared git configuration for personal repositories
  personalGitConfig = {
    user = {
      email = personalEmail;
      name = "reisholmes";
    };
    gpg.format = "ssh";
    user.signingkey = "~/.ssh/github_commit_signing_personal.pub";
    commit.gpgsign = true;
    url."git@github-personal:".insteadOf = [
      "git@github.com:"
      "https://github.com/"
    ];
  };
in {
  imports = [
    "${nhModules}/common"
    "${nhModules}/dev"
    inputs.stylix.homeModules.stylix
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";

  # Host-specific shell aliases
  programs.zsh.shellAliases = {
    nix_rebuild = "sudo darwin-rebuild switch --flake ~/Documents/code/personal_repos/nixCombined#reisholmes && nvd diff $(/bin/ls -d1v /nix/var/nix/profiles/system-*-link | tail -2 | head -1) $(/bin/ls -d1v /nix/var/nix/profiles/system-*-link | tail -1)";
  };

  # SSH signing configuration for git (both personal and work keys)
  programs.git.sshSigning = {
    enable = true;
    allowedSigners = [
      {
        email = personalEmail;
        key = userConfig.signingKeyPub;
      }
      {
        email = userConfig.workEmail;
        key = userConfig.workSigningKeyPub;
      }
    ];
    sshKeygenProgram = "/usr/bin/ssh-keygen"; # Use system ssh-keygen on macOS
    forceFileUpdate = true; # Force update on Darwin
  };

  # Git configuration
  programs.git = {
    # Git settings (new format)
    settings = {
      # No default email - work email stays out of nix, personal email set in conditional includes
    };

    # Conditional includes for work/personal repositories
    includes = [
      # Work repositories
      {
        condition = "gitdir:~/Documents/code/repos/";
        contents = {
          user = {
            name = "Reis Holmes";
            email = userConfig.workEmail;
          };
          gpg.format = "ssh";
          user.signingkey = "~/.ssh/github_work_signing.pub";
          commit.gpgsign = true;
          url = {
            "git@github-work:".insteadOf = [
              "git@github.com:"
              "https://github.com/"
            ];
            "github-work:optimizely/".insteadOf = [
              "git@github.com:optimizely/"
              "https://github.com/optimizely/"
            ];
            "github-work:episerver/".insteadOf = [
              "https://github.com/episerver/"
            ];
          };
        };
      }
      # Personal repositories
      {
        condition = "gitdir:~/Documents/code/personal_repos/";
        contents = personalGitConfig;
      }
      # Neovim configuration
      {
        condition = "gitdir:~/.config/nvim/";
        contents = personalGitConfig;
      }
    ];
  };

  # Stylix configuration for darwin home-manager
  # Note: stylix.darwinModules has compatibility issues, so we use home-manager module instead
  stylix = {
    enable = true;

    # No wallpaper set - company-managed on work machine
    # base16Scheme and fonts inherited from stylix-common.nix

    # Disable theming for apps that have manual configuration or that cause overlay conflicts
    targets = {
      lazygit.enable = false;
      ghostty.enable = false;
      gtk.enable = false;
      gnome.enable = false;
      kde.enable = false;
      kitty.enable = false;
    };
  };
}
