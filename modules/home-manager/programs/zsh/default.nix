{pkgs, ...}: {
  # ZSH
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    defaultKeymap = "viins";
    enableCompletion = false;

    initContent = ''
      unameOutput="$(uname -m)"

      # Handle non-interactive shells (like Claude Code, LLM tools, CI/CD)
      # Zoxide's cd override causes issues in non-interactive sessions
      if [[ ! -o interactive ]]; then
        # Unset zoxide's cd alias if it was set by oh-my-zsh
        unalias cd 2>/dev/null || true
        # Define standard cd behavior
        builtin cd() {
          builtin cd "$@"
        }
      fi

      # homebrew on M based Mac chips
      if [[ $unameOutput == 'arm64' ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"

        # macOS keyboard mapping for fzf
        # https://github.com/junegunn/fzf/issues/164#issuecomment-527826925
        bindkey "ç" fzf-cd-widget
      fi

      # for atuin
      eval "$(atuin init zsh)"

      # for az cli - defer completions loading
      autoload -U +X bashcompinit && bashcompinit

      # Lazy load az completions only when needed
      if [[ $unameOutput == 'arm64' ]]; then
        # Defer az completion loading until first use
        az() {
          unfunction az
          if [[ -f "/opt/homebrew/etc/bash_completion.d/az" ]]; then
            source /opt/homebrew/etc/bash_completion.d/az
          fi
          az "$@"
        }
      fi

      # for oh-my-posh
      eval "$(${pkgs.oh-my-posh}/bin/oh-my-posh init zsh --config ~/catppuccin.omp.json)"

      # https://old.reddit.com/r/KittyTerminal/comments/13ephdh/xtermkitty_ssh_woes_i_know_about_the_kitten_but/https://old.reddit.com/r/KittyTerminal/comments/13ephdh/xtermkitty_ssh_woes_i_know_about_the_kitten_but/
      # fixes unknown terminal prompt on SSH sessions
      [[ "$TERM" == "xterm-kitty" ]] && alias ssh="TERM=xterm-256color ssh"
      # fixes unknown terminal prompt on sudo vim commands
      alias vim="TERM=xterm-256color vim"

      # nixpkgs allow unfree for "nvidia"
      export NIXPKGS_ALLOW_UNFREE=1

      # lf icons support - cache the icons to avoid reading file every time
      if [[ -z "$LF_ICONS" && -f ~/.config/lf/icons ]]; then
        export LF_ICONS=$(cat ~/.config/lf/icons)
      fi

      # Only run fastfetch in login shells or first shell (check if it's a new terminal)
      if [[ -o login ]] || [[ "$SHLVL" -eq 1 ]]; then
        fastfetch
      fi

    '';

    sessionVariables =
      if pkgs.stdenv.isDarwin
      then {
        DISABLE_PROMPT_CACHING = "0";
      }
      else {};

    shellAliases = {
      # modern cat command remap
      cat = "bat";

      # Next level of an ls
      #options :  --no-filesize --no-time --no-permissions
      ls = "eza --no-filesize --long --color=always --icons=always --no-user";

      # list tree
      lt = "lsd --tree";

      lg = "lazygit";
    };
    syntaxHighlighting.enable = true;

    plugins = [
      {
        # will source zsh-autosuggestions.plugin.zsh
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.0";
          # this shows how to get a sha256, run the flake build and it will error with the real sha
          # sha256 = pkgs.lib.fakeSha256;
          # or you can run nix-prefetch-git https://<url>
          sha256 = "KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
        };
      }
      {
        # will source zsh-autocomplete.plugin.zsh
        name = "zsh-autocomplete";
        src = pkgs.fetchFromGitHub {
          owner = "marlonrichert";
          repo = "zsh-autocomplete";
          rev = "25.03.19";
          # this shows how to get a sha256, run the flake build and it will error with the real sha
          # sha256 = pkgs.lib.fakeSha256;
          # or you can run nix-prefetch-git https://<url>
          sha256 = "eb5a5WMQi8arZRZDt4aX1IV+ik6Iee3OxNMCiMnjIx4=";
        };
      }
    ];

    oh-my-zsh = {
      enable = true;

      plugins = [
        "git"
        "zoxide"
      ];
    };
  };
}
