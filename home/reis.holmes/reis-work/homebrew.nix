{
  #https://mynixos.com/nix-darwin/options/homebrew

  # uninstall or zap, zap may remove files other programs require
  onActivation.cleanup = "uninstall";

  # directory (and usually git repo) of formulae, casks, and/or external cmds
  taps = [
    "deskflow/homebrew-tap"
    "hashicorp/tap"
    "jesseduffield/lazydocker"
    "powershell/tap"
  ];

  # typically pre compiled binaries
  brews = [
    "adr-tools"
    "awscli"
    "azure-cli"
    "lazydocker"
    "podman"
  ];

  # Homebrew package definition that installs macOS native applications
  # Casks offer a way to cmd line manage installs of Graphical apps
  casks = [
    "1password"
    "deskflow"
    "gcloud-cli"
    "powershell"
    # raycast shortcut setup
    # https://www.youtube.com/watch?v=DBifQv9AYhc
    "raycast"
    # remote desktop
    "windows-app"
  ];

  # MacStore apps, have to be logged in
  # search for apps using mas cli
  # mas list, mas search "xxx"
  masApps = {
    # "windows app" = 1295203466;
  };
}
