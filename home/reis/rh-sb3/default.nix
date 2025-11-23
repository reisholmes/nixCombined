{
  config,
  nhModules,
  nixgl,
  pkgs,
  userConfig,
  ...
}: {
  imports = [
    "${nhModules}/common"
    "${nhModules}/dev"
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";

  # Host-specific shell aliases
  programs.zsh.shellAliases = {
    nix_rebuild = "home-manager switch --flake .#reis@rh-sb3 --impure && nvd diff $(home-manager generations | head -2 | tail -1 | awk '{print $7}') $(home-manager generations | head -1 | awk '{print $7}')";
  };

  # SSH signing configuration for git
  programs.git.sshSigning = {
    enable = true;
    allowedSigners = [
      {
        email = userConfig.email;
        key = userConfig.signingKeyPub;
      }
    ];
  };

  # Git configuration
  programs.git = {
    # Enable SSH signing globally (personal computer - all repos signed)
    signing = {
      key = "${config.home.homeDirectory}/.ssh/private-signing-key-github";
      signByDefault = true;
    };

    # Git settings (new format)
    settings = {
      # Set personal email from userConfig
      user.email = userConfig.email;
    };
  };

  # NixGL configuration for standalone home-manager on Linux
  nixgl = {
    enable = true;
    profile = "nvidiaPrime";
  };

  # gtk styling settings
  gtk = {
    cursorTheme = {
      name = "XCursor-Pro-Dark";
    };
    iconTheme = {
      name = "Mint-Y-Blue";
    };
    theme = {
      name = "Catppuccin-GTK-Dark";
    };
  };

  # Stylix settings specific to this machine
  stylix = {
    enable = true;

    # Host-specific wallpaper
    # https://basicappleguy.com/basicappleblog/strokes
    hostConfig.wallpaper = ../../../modules/home-manager/assets/stylix/wallpaper_wave_mac.jpg;

    # Font sizes and base16Scheme inherited from stylix-common.nix module
  };
}
