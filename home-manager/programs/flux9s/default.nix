# What: Home-manager aspect installing flux9s with a Catppuccin Mocha theme.
# Used by: Imported by home-manager/dev/default.nix.
{pkgs, ...}: {
  home.packages = [pkgs.flux9s];

  home.file.".config/flux9s/config.yaml".source = ../../assets/flux9s/config.yaml;
}
