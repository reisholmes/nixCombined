{
  nhModules,
  nixgl,
  ...
}: {
  imports = [
    "${nhModules}/common"
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";

  # NixGL
  nixGL = {
    packages = nixgl.packages;

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
    # wallpaper https://stylix.danth.me/configuration.html#wallpaper
    # https://basicappleguy.com/basicappleblog/strokes
    image = ../../../modules/home-manager/assets/stylix/wallpaper_wave_mac.jpg;

    # fonts https://stylix.danth.me/configuration.html#fonts
    fonts = {
      # sizing https://stylix.danth.me/options/platforms/nixos.html#stylixfontssizesapplications
      sizes = {
        applications = 10;
        desktop = 10;
        popups = 10;
        terminal = 12;
      };
    };
  };
}
