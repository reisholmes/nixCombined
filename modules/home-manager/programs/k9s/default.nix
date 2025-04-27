{
  pkgs,
  userConfig,
  ...
}: {
  # https://home-manager-options.extranix.com/?query=programs.k9s&release=master
  # https://github.com/catppuccin/k9s
  #  home.file."/Users/reis.holmes/Library/Application Support/k9s/views.yaml" = {
  #  source = ./views.yaml;
  #};
  home = {
    file = {
      k9sSkin = {
        source = ../../assets/k9s/catppuccin-mocha.yaml;
        target =
          if pkgs.stdenv.isDarwin
          then "/Users/${userConfig.name}/Users/${userConfig.name}/Library/Application Support/k9s/skins/catppuccin-mocha.yaml"
          else "/home/${userConfig.name}/.config/k9s/skins/catppuccin-mocha.yaml";
      };
    };
    file = {
      k9sViews = {
        source = ../../assets/k9s/views.yaml;
        target =
          if pkgs.stdenv.isDarwin
          then "/Users/${userConfig.name}/Users/${userConfig.name}/Library/Application Support/k9s/views.yaml"
          else "/home/${userConfig.name}/.config/k9s/views.yaml";
      };
    };
  };
  programs.k9s = {
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
}
