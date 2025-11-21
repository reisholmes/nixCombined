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
    nix_rebuild = "home-manager switch --flake .#reis@reis-new --impure -b backup && nvd diff $(home-manager generations | head -2 | tail -1 | awk '{print $7}') $(home-manager generations | head -1 | awk '{print $7}')";
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

  # Packages specific to this machine
  home.packages = with pkgs; [
    lm_sensors
  ];

  # NixGL settings specific to this machine
  targets.genericLinux.nixGL = {
    inherit (nixgl) packages;

    defaultWrapper = "nvidia";
    vulkan.enable = true;
  };

  # Stylix settings specific to this machine
  stylix = {
    enable = true;
    autoEnable = true;

    # wallpaper https://stylix.danth.me/configuration.html#wallpaper
    # https://basicappleguy.com/basicappleblog/mountains-beyond-mountains
    image = ../../../modules/home-manager/assets/stylix/wallpaper_mountain_mac.png;

    # Font sizes are inherited from stylix-common.nix module
    # fonts https://stylix.danth.me/configuration.html#fonts
  };
}
