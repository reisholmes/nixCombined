{
  lib,
  pkgs,
  ...
}: {
  # ZSH
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    defaultKeymap = "viins";
    enableCompletion = true;

    # Useful shell options for better navigation and UX
    setOptions = [
      # "AUTOCD" removed - causes shell to exit when commands include flags like -la
      "AUTOPUSHD" # Make cd push old directory onto directory stack
      "HIST_VERIFY" # Show command before executing from history
      "PUSHD_IGNORE_DUPS" # Don't push duplicate directories
    ];

    # Allow unfree packages (e.g., nvidia drivers)
    envExtra = ''
      export NIXPKGS_ALLOW_UNFREE=1
    '';

    initContent = ''
      # Handle non-interactive shells (like Claude Code, LLM tools, CI/CD)
      # Zoxide's cd override causes issues in non-interactive sessions
      if [[ ! -o interactive ]]; then
        # Unset zoxide's cd alias if it was set
        unalias cd 2>/dev/null || true
        # Define standard cd behavior
        builtin cd() {
          builtin cd "$@"
        }
      fi

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        # Homebrew initialization (Darwin-only)
        # Set brew prefix based on architecture: ARM64 uses /opt/homebrew, Intel uses /usr/local
        if [[ $(uname -m) == 'arm64' ]]; then
          BREW_PREFIX="/opt/homebrew"
        else
          BREW_PREFIX="/usr/local"
        fi
        eval "$($BREW_PREFIX/bin/brew shellenv)"

        # macOS keyboard mapping for fzf
        # https://github.com/junegunn/fzf/issues/164#issuecomment-527826925
        bindkey "ç" fzf-cd-widget
      ''}

      # for atuin
      eval "$(atuin init zsh)"

      # for az cli - defer completions loading
      autoload -U +X bashcompinit && bashcompinit

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        # Lazy load az completions only when needed (Darwin-only)
        az() {
          unfunction az
          if [[ -f "$BREW_PREFIX/etc/bash_completion.d/az" ]]; then
            source "$BREW_PREFIX/etc/bash_completion.d/az"
          fi
          az "$@"
        }
      ''}

      # for oh-my-posh
      eval "$(${pkgs.oh-my-posh}/bin/oh-my-posh init zsh --config ~/catppuccin.omp.json)"

      # https://old.reddit.com/r/KittyTerminal/comments/13ephdh/xtermkitty_ssh_woes_i_know_about_the_kitten_but/https://old.reddit.com/r/KittyTerminal/comments/13ephdh/xtermkitty_ssh_woes_i_know_about_the_kitten_but/
      # fixes unknown terminal prompt on SSH sessions
      [[ "$TERM" == "xterm-kitty" ]] && alias ssh="TERM=xterm-256color ssh"
      # fixes unknown terminal prompt on sudo vim commands
      alias vim="TERM=xterm-256color vim"

      # lf icons support - cache the icons to avoid reading file every time
      if [[ -z "$LF_ICONS" && -f ~/.config/lf/icons ]]; then
        export LF_ICONS=$(cat ~/.config/lf/icons)
      fi

      # Only run fastfetch in login shells or first shell (check if it's a new terminal)
      if [[ -o login ]] || [[ "$SHLVL" -eq 1 ]]; then
        fastfetch
      fi

    '';

    sessionVariables = lib.optionalAttrs pkgs.stdenv.isDarwin {
      # Darwin-only: disable prompt caching
      DISABLE_PROMPT_CACHING = "0";
    };

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
      # zsh-autocomplete removed - causes shell crashes with -la flags and has known stability issues
      # Using programs.zsh.autosuggestion.enable = true instead (zsh-autosuggestions is more stable)
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
  };
}
