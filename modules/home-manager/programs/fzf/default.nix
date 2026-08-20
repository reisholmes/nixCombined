_: {
  # fzf
  programs.fzf = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;

    # https://github.com/Sin-cy/dotfiles/blob/main/zsh/.zshrc
    # https://github.com/nix-community/home-manager/blob/master/modules/programs/fzf.nix
    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
    defaultOptions = ["--height 50%" "--layout=default" "--border" "--color=hl:#2dd4bf"];
    # Command that gets executed when pressing ctrl+t
    fileWidget.command = "fd --hidden --strip-cwd-prefix --exclude .git";
    fileWidget.options = ["--preview 'bat --color=always -n --line-range :500 {}'"];
    # Command that gets executed when pressing ctrl+c
    changeDirWidget.command = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidget.options = ["--preview 'eza --icons=always --tree --color=always {} | head -200'"];

    # atuin owns history
    historyWidget.command = "";
  };
}
