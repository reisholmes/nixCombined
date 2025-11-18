{
  lib,
  pkgs,
  ...
}: {
  # Shared Stylix configuration for all systems
  # Use lib.mkDefault to allow individual machines to override
  #
  # Example: To override on a specific machine, add to that machine's config:
  # stylix.fonts.sizes = {
  #   applications = 12;  # Override just this one
  #   desktop = 10;       # Or override all of them
  #   popups = 10;
  #   terminal = 14;
  # };
  stylix = {
    # Base16 color scheme - can be overridden per-host
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # Font configuration - can be overridden per-host
    fonts = lib.mkDefault {
      serif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Serif";
      };
      sansSerif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Sans";
      };
      monospace = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      # Font sizes
      sizes = {
        applications = 10;
        desktop = 10;
        popups = 10;
        terminal = 12;
      };
    };
  };
}
