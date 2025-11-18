{
  config,
  pkgs,
  wrapWithNixGL,
  ...
}: {
  # https://home-manager-options.extranix.com/?query=programs.kitty&release=master
  # Kitty
  programs.kitty = {
    enable = false;

    package = wrapWithNixGL pkgs.kitty;

    keybindings = {
      "ctrl+shift+enter" = "new_window_with_cwd";
      "ctrl+shift+t" = "new_tab_with_cwd";
    };
    settings = {
      active_border_color = "#a6da95";
      background_blur = 32;
      background_opacity = "0.95";
      cursor_shape = "beam";
      font_family = "Hack Nerd Font Mono";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      # Use stylix terminal font size as base, with platform-specific adjustments
      font_size =
        if pkgs.stdenv.isDarwin
        then config.stylix.fonts.sizes.terminal + 3.5 # 12 + 3.5 = 15.5
        else config.stylix.fonts.sizes.terminal + 2; # 12 + 2 = 14

      macos_option_as_alt = "yes";
      initial_window_height = 44;
      initial_window_width = 160;
      remember_window_size = "yes";
      titlebar-only = "yes";
      hide_window_decorations = "titlebar-only";
      placement_strategy = "center";
      window_border_width = "1pt";
      window_margin_width = 1;
      # fun with cursor trails
      cursor_trail = 3;
      cursor_trail_decay = "0.2 0.3";
    };
    themeFile = "Catppuccin-Mocha";
  };
}
