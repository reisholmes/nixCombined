# What: Home-manager aspect configuring nix-search-tv and its index update script.
# Used by: Imported by home-manager/common/default.nix.
{pkgs, ...}: {
  # https://github.com/3timeslazy/nix-search-tv
  # https://github.com/3timeslazy/nix-search-tv?tab=readme-ov-file#configuration
  # nix-search-tv
  programs.nix-search-tv = {
    enable = true;

    settings = {
      indexes = ["nixpkgs" "home-manager"];
    };
  };
  home = {
    packages = with pkgs; [
      #nix-search-tv
      (pkgs.writeShellApplication {
        name = "nix-search";
        runtimeInputs = with pkgs; [
          fzf
          nix-search-tv
        ];
        text = builtins.readFile ../../assets/nix-search-tv/nix-search.tv.sh;
      })
    ];
  };
}
