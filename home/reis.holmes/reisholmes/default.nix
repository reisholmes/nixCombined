{
  nhModules,
  inputs,
  outputs,
  pkgs,
  ...
}: {
  imports = [
    "${nhModules}/common"
    "${nhModules}/dev"
    inputs.stylix.homeModules.stylix
  ];

  # Nixpkgs configuration for darwin home-manager
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # Enable home-manager
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";

  # Stylix configuration for darwin home-manager
  # Note: stylix.darwinModules has compatibility issues, so we use home-manager module instead
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    image = ../../modules/home-manager/assets/stylix/wallpaper_wave_mac.jpg;

    # Disable theming for apps that have manual configuration or that cause overlay conflicts
    targets = {
      lazygit.enable = false;
      ghostty.enable = false;
      gtk.enable = false;
      gnome.enable = false;
      kde.enable = false;
      kitty.enable = false;
    };

    fonts = {
      serif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Serif";
      };
      sansSerif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Sans";
      };
      monospace = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
