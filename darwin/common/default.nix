# What: Shared nix-darwin system module for macOS hosts: system defaults, packages, GC.
# Used by: Imported by darwin/hosts/reisholmes.nix.
{
  pkgs,
  outputs,
  ...
}: {
  # Nixpkgs configuration
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
    overlays = [
      outputs.overlays.stable-packages
      outputs.overlays.pipx-fix
    ];
  };

  # Nix daemon settings
  nix = {
    # Automatic garbage collection
    gc = {
      automatic = true;
      interval = [
        {
          Hour = 3;
          Minute = 15;
          Weekday = 7; # Sunday
        }
      ];
      options = "--delete-older-than 21d";
    };

    # Automatic store optimization (deduplicate identical files)
    optimise.automatic = true;

    package = pkgs.nix;

    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  # System fonts - Installed to /Library/Fonts/Nix Fonts
  fonts.packages = with pkgs; [
    ibm-plex
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji
  ];

  # Security - Enable TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
}
