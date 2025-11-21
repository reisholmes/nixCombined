{
  config,
  nhModules,
  nixgl,
  pkgs,
  userConfig,
  ...
}: let
  # Generate allowed_signers file for SSH commit verification
  allowedSignersFile = pkgs.writeText "git-allowed-signers" ''
    ${userConfig.email} ${userConfig.signingKeyPub}
  '';
in {
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

  # Create allowed_signers file for git SSH signing
  home.file.".ssh/allowed_signers".source = allowedSignersFile;

  # Git configuration
  programs.git = {
    # Enable SSH signing globally (personal computer - all repos signed)
    signing = {
      key = "/home/reis/.ssh/private-signing-key-github";
      signByDefault = true;
    };

    # Git settings (new format)
    settings = {
      # Set personal email from userConfig
      user.email = userConfig.email;

      # SSH signing configuration
      gpg.format = "ssh";
      gpg.ssh = {
        allowedSignersFile = "/home/reis/.ssh/allowed_signers";
      };
    };
  };

  # NixGL configuration for standalone home-manager on Linux
  targets.genericLinux.nixGL = {
    inherit (nixgl) packages;
    defaultWrapper = "mesa";
    offloadWrapper = "nvidiaPrime";
    # vulkan.enable = true; # not yet tested on sb3, could be fine
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
    autoEnable = true;

    # wallpaper https://stylix.danth.me/configuration.html#wallpaper
    # https://basicappleguy.com/basicappleblog/strokes
    image = ../../../modules/home-manager/assets/stylix/wallpaper_wave_mac.jpg;

    # Font sizes are inherited from stylix-common.nix module
    # fonts https://stylix.danth.me/configuration.html#fonts
  };
}
