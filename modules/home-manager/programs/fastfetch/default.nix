{config, ...}: {
  # fastfetch
  programs.fastfetch = {
    enable = true;

    # https://mynixos.com/home-manager/option/programs.fastfetch.settings
    # https://github.com/fastfetch-cli/fastfetch/wiki/Json-Schema
  };
  home = {
    file = {
      fastfetchSettings = {
        source = ../../assets/fastfetch/reis.jsonc;
        target = "${config.home.homeDirectory}/.config/fastfetch/config.jsonc";
      };
    };
  };
}
