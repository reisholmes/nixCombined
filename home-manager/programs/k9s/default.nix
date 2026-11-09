# k9s — Kubernetes TUI with Catppuccin Mocha theme and custom pod view.
#
# Config paths differ by platform: ~/Library/Application Support/k9s on
# macOS, ~/.config/k9s on Linux. The skin and views assets are imported
# from ../../assets/k9s/.
{pkgs, ...}: let
  k9sConfigDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "Library/Application Support/k9s"
    else ".config/k9s";
in {
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

  home.file = {
    "${k9sConfigDir}/views.yaml".source = ../../assets/k9s/views.yaml;
    "${k9sConfigDir}/skins/catppuccin-mocha.yaml".source = ../../assets/k9s/catppuccin-mocha.yaml;
  };
}
