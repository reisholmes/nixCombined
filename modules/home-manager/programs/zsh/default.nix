{pkgs, lib, ...}: {
  # ZSH
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    defaultKeymap = "viins";
    enableCompletion = false;

    initExtraBeforeCompInit = ''
      eval "$(brew shellenv)"
    '';

    initContent = lib.mkOrder 500 '''
      # mac is dumb
      # https://github.com/junegunn/fzf/issues/164#issuecomment-527826925
      bindkey "ç" fzf-cd-widget

      # for atuin
      eval "$(atuin init zsh)"
      eval "$(oh-my-posh init zsh)"

      # for az cli
      autoload bashcompinit && bashcompinit
      source $(brew --prefix)/etc/bash_completion.d/az

      # for oh-my-posh
      eval "$(${pkgs.oh-my-posh}/bin/oh-my-posh init zsh --config ~/catppuccin.omp.json)"


      # https://old.reddit.com/r/KittyTerminal/comments/13ephdh/xtermkitty_ssh_woes_i_know_about_the_kitten_but/https://old.reddit.com/r/KittyTerminal/comments/13ephdh/xtermkitty_ssh_woes_i_know_about_the_kitten_but/
      # fixes unknown terminal prompt on SSH sessions
      [[ "$TERM" == "xterm-kitty" ]] && alias ssh="TERM=xterm-256color ssh"

    ''';

    shellAliases = {
      # easier rebuilding on darwin
      nix_rebuild = "darwin-rebuild switch --flake /Users/reis.holmes/Documents/code/repos/nix-darwin/#reis-work";

      # modern cat command remap
      cat = "bat";

      # Next level of an ls
      #options :  --no-filesize --no-time --no-permissions
      ls = "eza --no-filesize --long --color=always --icons=always --no-user";
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
          #this shows how to get a sha256, run the flake build and it will error with the real sha
          #sha256 = pkgs.lib.fakeSha256;
          sha256 = "KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
        };
      }
      {
        # will source zsh-autosuggestions.plugin.zsh
        name = "zsh-autocomplete";
        src = pkgs.fetchFromGitHub {
          owner = "marlonrichert";
          repo = "zsh-autocomplete";
          rev = "24.09.04";
          #this shows how to get a sha256, run the flake build and it will error with the real sha
          #sha256 = pkgs.lib.fakeSha256;
          sha256 = "o8IQszQ4/PLX1FlUvJpowR2Tev59N8lI20VymZ+Hp4w=";
        };
      }
    ];

    oh-my-zsh = {
      enable = true;

      plugins = [
        "git"
        "zoxide"
        #  "z"
      ];
    };
  };
}
