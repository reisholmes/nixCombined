{
  pkgs,
  userConfig,
  ...
}: {
  # fastfetch
  programs.fastfetch = {
    enable = true;
    package = pkgs.fastfetch;

    # https://mynixos.com/home-manager/option/programs.fastfetch.settings
    # https://github.com/fastfetch-cli/fastfetch/wiki/Json-Schema
  };
  home = {
    file = {
      fastfetchSettings = {
        source = ../../assets/fastfetch/reis.jsonc;
        target =
          if pkgs.stdenv.isDarwin
          then "/Users/${userConfig.name}/.config/fastfetch/config.jsonc"
          else "/home/${userConfig.name}/.config/fastfetch/config.jsonc";
      };
    };
  };
}
