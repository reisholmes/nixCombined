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

  # Host-specific shell aliases
  programs.zsh.shellAliases = {
    nix_rebuild = "home-manager switch --flake .#reis@reis-new --impure -b backup && nvd diff $(home-manager generations | head -2 | tail -1 | awk '{print $NF}') $(home-manager generations | head -1 | awk '{print $NF}')";
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
