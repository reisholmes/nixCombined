{
  pkgs,
  userConfig,
  nhModules,
  ...
}: {
  # https://github.com/3timeslazy/nix-search-tv
  # https://github.com/3timeslazy/nix-search-tv?tab=readme-ov-file#configuration
  # nix-search-tv
  programs.nix-search-tv = {
    enable = true;

    settings = {
      indexes = ["nixpkgs" "home-manager"];
    };
  };
  # disable xdg auto config so we can inject our own
  # https://github.com/nix-community/home-manager/issues/5539#issuecomment-2172568260
  # xdg.configFile."nix-search-tv/config.json".enable = false;
  home = {
    packages = with pkgs; [
      #nix-search-tv
      (pkgs.writeShellApplication {
        name = "nix-search";
        runtimeInputs = with pkgs; [
          fzf
          nix-search-tv
        ];
        text = builtins.readFile "${nhModules}/assets/nix-search-tv/nix-search.tv.sh";
      })
    ];
  };
}
