{
  nhModules,
  nixgl,
  pkgs,
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

  # Packages specific to this
  home.packages = with pkgs; [
    #coolercontrol.coolercontrold
    #coolercontrol.coolercontrol-gui
    #coolercontrol.coolercontrol-liqctld
    #coolercontrol.coolercontrol-ui-data
    lm_sensors
  ];

  # NixGL settings specific to this machine
  targets.genericLinux.nixGL = {
    packages = nixgl.packages;

    defaultWrapper = "nvidia";
    vulkan.enable = true;
  };

  # Stylix settings specific to this machine
  stylix = {
    # wallpaper https://stylix.danth.me/configuration.html#wallpaper
    # https://basicappleguy.com/basicappleblog/mountains-beyond-mountains
    image = ../../../modules/home-manager/assets/stylix/wallpaper_mountain_mac.png;

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
