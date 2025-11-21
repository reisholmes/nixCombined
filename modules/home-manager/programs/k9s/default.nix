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
        };
      };
    };
  };
}
