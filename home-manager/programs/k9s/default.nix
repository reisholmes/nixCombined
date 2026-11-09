# What: Home-manager aspect configuring k9s with a Catppuccin skin and custom views.
# Used by: Imported by home-manager/dev/default.nix.
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
