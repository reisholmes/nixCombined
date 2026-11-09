# opencode -- AI coding TUI with system theme (inherits catppuccin-mocha
# from the terminal emulator).
#
# Installed via Homebrew (macOS only). Only tui.json is managed here.
#
# opencode.json is NOT managed by nix. It contains secrets, internal
# URLs, usernames, and org-specific provider config that must not be
# committed to a public repo. Maintain it separately (e.g. a private
# vault or password manager) and place it at:
#   ~/.config/opencode/opencode.json
#
# Note: OpenCode does not support a custom status line command like
# Claude Code's statusLine option. Status info is accessible via
# <leader>s in the TUI.
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
