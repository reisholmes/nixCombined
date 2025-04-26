{...}: {
  # Install atuin via home-manager module
  programs.atuin = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;

    settings = {
      ctrl_n_shortcuts = false;
      inline_height = 25;
      invert = true;
      keymap_mode = "vim-insert";
      records = true;
      search_mode = "skim";
      secrets_filter = true;
      style = "compact";
    };
    #flags = ["--disable-up-arrow"];
  };
}
