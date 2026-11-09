# What: Declarative Homebrew packages and taps for nix-darwin.
# Used by: Imported by the darwin host module (darwin/hosts/reisholmes.nix today).
_: {
  homebrew = {
    enable = true;

    # Cleanup strategy: "none" leaves packages that are not in this config installed.
    # "uninstall" is disabled because on Homebrew 7.0.11 `brew bundle --force-cleanup`
    # deletes ~/.homebrew/trust.json and then fails on the untrusted deskflow tap.
    # That failure aborts activation before home-manager runs.
    # To list packages that are not in this config (nix-darwin writes the Brewfile to the Nix store):
    #   brew bundle cleanup --file="$(grep -o '/nix/store/[^ '\'']*-Brewfile' /run/current-system/activate | head -1)"
    # Set back to "uninstall" once a Homebrew release keeps the trust file.
    onActivation.cleanup = "none";

    # Homebrew taps (third-party repositories)
    # Format: "owner/repo"
    taps = [
      "deskflow/homebrew-tap"
      "hashicorp/tap"
      "jesseduffield/lazydocker"
      "powershell/tap"
    ];

    # Brews (command-line tools, typically pre-compiled binaries)
    brews = [
      "adr-tools"
      "awscli"
      "azure-cli"
      "lazydocker"
      "node"
      "opencode"
      "podman"
      "uv"
    ];

    # Casks (macOS native GUI applications)
    # Managed via command line for declarative installs
    casks = [
      "deskflow"
      "gcloud-cli"
      "ghostty"
      "powershell"
      "proton-pass"
      # Raycast setup: https://www.youtube.com/watch?v=DBifQv9AYhc
      "raycast"
      # Remote desktop client
      "windows-app"
    ];

    # Mac App Store apps (requires being logged in)
    # Find app IDs with: mas search "app name"
    # List installed: mas list
    masApps = {
      # Example: "App Name" = 1234567890;
    };
  };
}
