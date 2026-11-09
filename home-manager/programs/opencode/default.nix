# What: Home-manager aspect managing opencode's tui.json only.
# Used by: Imported by home-manager/dev/default.nix.
{
  pkgs,
  lib,
  ...
}: let
  tuiConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "system";
  };
in
  lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    home.file = {
      ".config/opencode/tui.json".text = tuiConfig;
    };
  }
