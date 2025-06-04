{
  config,
  pkgs,
  userConfig,
  ...
}: {
  # https://home-manager-options.extranix.com/?query=programs.ghostty&release=master
  # Ghostty
  programs.ghostty = {
    enable = true;

    package =
      if pkgs.stdenv.isDarwin
      then pkgs.ghostty
      else config.lib.nixGL.wrap pkgs.ghostty;

    #enableBatSyntax = true;
    #enableZshIntegration = true;

    #settings = {
    #};
  };
  # disable xdg auto config so we can inject our own
  # https://github.com/nix-community/home-manager/issues/5539#issuecomment-2172568260
  xdg.configFile."ghostty/config".enable = false;
  home = {
    file = {
      ghosttySettings = {
        source = ./config;
        target =
          if pkgs.stdenv.isDarwin
          then "/Users/${userConfig.name}/.config/ghostty/config"
          else "/home/${userConfig.name}/.config/ghostty/config";
      };
    };
  };
}
