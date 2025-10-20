{
  pkgs,
  outputs,
  userConfig,
  ...
}: {
  # Homebrew
  homebrew = import ../../home/reis.holmes/reis-work/homebrew.nix // {enable = true;};

  # Nixpkgs configuration
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
    hostPlatform = "aarch64-darwin";
    overlays = [
      outputs.overlays.stable-packages
    ];
  };

  # Nix settings
  nix = {
    gc = {
      automatic = true;
      interval = [
        {
          Hour = 3;
          Minute = 15;
          Weekday = 7;
        }
      ];
      options = "--delete-older-than 21d";
    };
    optimise.automatic = true;
    package = pkgs.nix;
    settings = {
      experimental-features = "nix-command flakes";
    };
  };

  # User configuration
  users.users.${userConfig.name} = {
    name = "${userConfig.name}";
    home = "/Users/${userConfig.name}";
  };

  # Add ability to use TouchID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Define the primary user
  system.primaryUser = "reis.holmes";
  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 5;
}
