{
  pkgs,
  outputs,
  userConfig,
  inputs,
  self,
  ...
}: {
  # Homebrew
  homebrew = import ../../home/reis.holmes/reisholmes/homebrew.nix // {enable = true;};

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

  # Note: Stylix darwin system-level module has compatibility issues (stylix.icons error)
  # Stylix configuration is handled at the home-manager level instead
  # See home/reis.holmes/reisholmes/default.nix for stylix config

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs outputs;
      userConfig = userConfig;
      nhModules = "${self}/modules/home-manager";
      nixgl = inputs.nixgl;
    };
    users.${userConfig.name} = import ../../home/${userConfig.name}/reisholmes;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 5;
}
