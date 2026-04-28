{
  lib,
  pkgs,
  ...
}: {
  # https://home-manager-options.extranix.com/?query=programs.k9s&release=master
  # k9s is only enabled on darwin systems
  programs.k9s = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;

    settings = {
      k9s = {
        refreshRate = 3;
        ui = {
          logoless = true;
          noIcons = false;
          skin = "catppuccin-mocha";
        };
      };
    };
  };

  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    "Library/Application Support/k9s/views.yaml".source = ../../assets/k9s/views.yaml;
    "Library/Application Support/k9s/skins/catppuccin-mocha.yaml".source = ../../assets/k9s/catppuccin-mocha.yaml;
  };
}
