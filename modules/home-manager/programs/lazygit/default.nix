{...}: {
  # LazyGit
  programs.lazygit = {
    enable = true;

    settings = {
      gui.nerdFontsVersion = "3";
      gui.theme = {
        # https://github.com/catppuccin/lazygit/blob/main/themes/macchiato/pink.yml
        activeBorderColor = ["#f5bde6" "bold"];
        inactiveBorderColor = ["#a5adcb"];
        optionsTextColor = ["#8aadf4"];
        selectedLineBgColor = ["#363a4f"];
        cherryPickedCommitBgColor = ["#494d64"];
        cherryPickedCommitFgColor = ["#f5bde6"];
        unstagedChangesColor = ["#ed8796"];
        defaultFgColor = ["#cad3f5"];
        searchingActiveBorderColor = ["#eed49f"];
      };
      gui.authorColors = {
        "*" = "#b7bdf8";
      };
    };
  };
}
