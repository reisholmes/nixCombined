{lib, ...}: {
  # Shared Stylix font size configuration
  # Use lib.mkDefault to allow individual machines to override
  #
  # Example: To override on a specific machine, add to that machine's config:
  # stylix.fonts.sizes = {
  #   applications = 12;  # Override just this one
  #   desktop = 10;       # Or override all of them
  #   popups = 10;
  #   terminal = 14;
  # };
  stylix.fonts.sizes = lib.mkDefault {
    applications = 10;
    desktop = 10;
    popups = 10;
    terminal = 12;
  };
}
