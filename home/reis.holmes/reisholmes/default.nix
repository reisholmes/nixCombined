{
  nhModules,
  inputs,
  ...
}: {
  imports = [
    "${nhModules}/common"
    "${nhModules}/dev"
    inputs.stylix.homeModules.stylix
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";

  # Host-specific shell aliases
  programs.zsh.shellAliases = {
    nix_rebuild = "sudo darwin-rebuild switch --flake ~/Documents/code/personal_repos/nixCombined#reisholmes && nvd diff $(ls -d1v /nix/var/nix/profiles/system-*-link | tail -2 | head -1) $(ls -d1v /nix/var/nix/profiles/system-*-link | tail -1)";
  };

  # Stylix configuration for darwin home-manager
  # Note: stylix.darwinModules has compatibility issues, so we use home-manager module instead
  stylix = {
    enable = true;
    image = ../../modules/home-manager/assets/stylix/wallpaper_wave_mac.jpg;

    # base16Scheme and fonts inherited from stylix-common.nix

    # Disable theming for apps that have manual configuration or that cause overlay conflicts
    targets = {
      lazygit.enable = false;
      ghostty.enable = false;
      gtk.enable = false;
      gnome.enable = false;
      kde.enable = false;
      kitty.enable = false;
    };
  };
}
