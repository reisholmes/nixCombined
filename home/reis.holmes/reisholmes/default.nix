{
  config,
  pkgs,
  nhModules,
  inputs,
  userConfig,
  ...
}:
let
  # Personal email for personal repos only (work email stays out of nix)
  personalEmail = "4367558+reisholmes@users.noreply.github.com";

  # Generate allowed_signers file for SSH commit verification
  allowedSignersFile = pkgs.writeText "git-allowed-signers" ''
    ${personalEmail} ${userConfig.signingKeyPub}
  '';
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

  # Create allowed_signers file for git SSH signing
  home.file.".ssh/allowed_signers".source = allowedSignersFile;

  # Git configuration
  programs.git = {
    # Git settings (new format)
    settings = {
      # No default email - work email stays out of nix, personal email set in conditional includes

      # SSH signing configuration
      gpg.format = "ssh";
      gpg.ssh = {
        allowedSignersFile = "~/.ssh/allowed_signers";
        program = "/usr/bin/ssh-keygen"; # Use system ssh-keygen on macOS
      };
    };

    # Conditional includes for work/personal repositories
    includes = [
      # Work repositories - email not set in nix (set manually if needed)
      {
        condition = "gitdir:~/Documents/code/repos/";
        contents = {
          user = {
            name = "Reis Holmes";
            # email = "work@company.com"; # Set this manually with: git config --global user.email "your-work-email"
          };
          commit.gpgsign = false; # Disable signing for work repos
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
        contents = {
          user = {
            email = personalEmail;
            name = "reisholmes";
          };
          gpg.format = "ssh";
          user.signingkey = "~/.ssh/github_commit_signing_personal.pub";
          commit.gpgsign = true;
          gpg.ssh = {
            program = "/usr/bin/ssh-keygen";
            allowedSignersFile = "~/.ssh/allowed_signers";
          };
          url."git@github-personal:".insteadOf = [
            "git@github.com:"
            "https://github.com/"
          ];
        };
      }
    ];
  };

  # Stylix configuration for darwin home-manager
  # Note: stylix.darwinModules has compatibility issues, so we use home-manager module instead
  stylix = {
    enable = true;
    image = ../../modules/home-manager/assets/stylix/wallpaper_wave_mac.jpg;

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
