# opencode -- AI coding TUI with system theme (inherits catppuccin-mocha
# from the terminal emulator).
#
# Installed via Homebrew (macOS only). Configuration managed here via
# home.file for opencode.json and tui.json.
#
# MCP servers migrated from Claude Code CLI: Cloudflare API,
# Cloudflare Observability. Permissions mirror the Claude Code
# read-only allow list for git/gh commands.
#
# Note: OpenCode does not support a custom status line command like
# Claude Code's statusLine option. Status info is accessible via
# <leader>s in the TUI.
{
  pkgs,
  lib,
  ...
}: let
  opencodeConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    shell = "/bin/zsh";

    mcp = {
      cloudflare-api = {
        type = "remote";
        url = "https://mcp.cloudflare.com/mcp";
      };
      cloudflare-observability = {
        type = "remote";
        url = "https://observability.mcp.cloudflare.com/mcp";
      };
    };

    permission = {
      read = "allow";
      glob = "allow";
      grep = "allow";
      list = "allow";
      lsp = "allow";
      bash = {
        "*" = "ask";
        "ls *" = "allow";
        "tree *" = "allow";
        "git *" = "allow";
        "gh *" = "allow";
        "nix *" = "allow";
        "rm *" = "deny";
      };
    };
  };

  tuiConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    theme = "system";
  };
in
  lib.mkIf pkgs.stdenv.isDarwin {
    home.file = {
      ".config/opencode/opencode.json".text = opencodeConfig;
      ".config/opencode/tui.json".text = tuiConfig;
    };
  }
