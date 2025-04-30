{...}: {
  # https://home-manager-options.extranix.com/?query=programs.k9s&release=master
  programs.k9s = {
    enable = true;

    settings = {
      k9s = {
        refreshRate = 3;
        ui = {
          logoless = true;
          noIcons = false;
        };
      };
    };
  };
}
