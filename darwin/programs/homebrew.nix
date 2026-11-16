# What: Declarative Homebrew packages and taps for nix-darwin.
# Used by: Imported by the darwin host module (darwin/hosts/reisholmes.nix today).
_: {
  homebrew = {
    enable = true;

    # nix-darwin runs `brew update` on each darwin-rebuild switch, then upgrades outdated
    # packages listed in this file. This makes rebuilds slower, needs network access, and means
    # two rebuilds of the same config can install different versions.
    # Manual `brew` commands auto-update through homebrew.global.autoUpdate, which defaults to true.
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    # nix-darwin uninstalls packages that are not in this config on each rebuild.
    # Cleanup resets ~/.homebrew/trust.json to the trust this Brewfile declares
    # (https://docs.brew.sh/Tap-Trust). Every non-official tap below must set
    # `trusted = true`, or cleanup drops its trust and activation fails before home-manager runs.
    # To preview what cleanup would remove (nix-darwin writes the Brewfile to the Nix store):
    #   brew bundle cleanup --file="$(grep -o '/nix/store/[^ '\'']*-Brewfile' /run/current-system/activate | head -1)"
    onActivation.cleanup = "uninstall";

    # Homebrew taps (third-party repositories)
    taps = [
      {
        name = "deskflow/homebrew-tap";
        trusted = true;
      }
    ];

    # Brews (command-line tools, typically pre-compiled binaries)
    brews = [
      "adr-tools"
      "awscli"
      "lazydocker"
      "node"
      "opencode"
      "podman"
      "uv"
      "vale"
    ];

    # Casks (macOS native GUI applications)
    # Managed via command line for declarative installs
    casks = [
      "azure-cli"
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
