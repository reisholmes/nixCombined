{
  config,
  pkgs,
  wrapWithNixGL,
  ...
}: {
  # https://home-manager-options.extranix.com/?query=programs.ghostty&release=master
  # Ghostty
  # On macOS, ghostty is installed via Homebrew for better system integration
  # On Linux, it's installed via Nix with nixGL wrapper
  programs.ghostty = {
    enable = !pkgs.stdenv.isDarwin;

    package = wrapWithNixGL pkgs.ghostty;
  };
  # disable xdg auto config so we can inject our own
  # https://github.com/nix-community/home-manager/issues/5539#issuecomment-2172568260
  xdg.configFile."ghostty/config".enable = false;
  home = {
    file = {
      ghosttySettings = {
        source = ./config;
        target = "${config.home.homeDirectory}/.config/ghostty/config";
      };
    };
  };
}
