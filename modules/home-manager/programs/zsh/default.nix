{
  pkgs,
  userConfig,
  ...
}: {
  # ZSH
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    defaultKeymap = "viins";
    enableCompletion = false;

    initContent = ''
      unameOutput="$(uname -m)"

      # homebrew on M based Mac chips
      if [[ $unameOutput == 'arm64' ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"

        # mac is dumb
        # https://github.com/junegunn/fzf/issues/164#issuecomment-527826925
        bindkey "ç" fzf-cd-widget
      fi

      # for atuin
      eval "$(atuin init zsh)"
      eval "$(oh-my-posh init zsh)"

      # for az cli
      autoload -U +X bashcompinit && bashcompinit

      if [[ $unameOutput == 'arm64' ]]; then
        #load the file
        source $(brew --prefix)/etc/bash_completion.d/az

      elif [[ $unameOutput == 'x86_64' ]]; then
        #load the file, do not care about az.bash completions outside of work
        #leaving in as an example of providing for different
        #source /home/${userConfig.name}/.nix-profile/share/bash-completion/completions/az.bash
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

      # Configuration for zsh-vi-mode
      #VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
      VI_MODE_SET_CURSOR=true

      # start Fastfetch
      fastfetch

    '';

    sessionVariables =
      if pkgs.stdenv.isDarwin
      then {
        ANTHROPIC_VERTEX_PROJECT_ID = "fillmein";
        ANTHROPIC_API_KEY = "fillmein";
        CLAUDE_CODE_USE_VERTEX = "1";
        CLOUD_ML_REGION = "us-central1";
        DISABLE_PROMPT_CACHING = "0";
        VERTEX_REGION_CLAUDE_4_0_SONNET = "us-east5";
        VERTEX_REGION_CLAUDE_4_5_SONNET = "global";
      }
      else {};

    shellAliases = {
      # easier rebuilding on darwin
      nix_work_rebuild = "darwin-rebuild switch --flake /Users/reis.holmes/Documents/code/repos/nix-darwin/#reis-work";

      # easier rebuilding on surface book
      nix_sb3_rebuild = "home-manager switch --flake .#reis@rh-sb3 --impure";

      # easier rebuilding on desktop
      nix_desktop_rebuild = "home-manager switch --flake .#reis@reis-new --impure -b backup";

      # modern cat command remap
      cat = "bat";

      # Next level of an ls
      #options :  --no-filesize --no-time --no-permissions
      ls = "eza --no-filesize --long --color=always --icons=always --no-user";

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
        "vi-mode"
      ];
    };
  };
}
