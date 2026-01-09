{
  outputs,
  userConfig,
  inputs,
  self,
  darwinModules,
  ...
}: {
  # Import darwin modules for common configurations
  imports = [
    "${darwinModules}/common"
    "${darwinModules}/programs/homebrew.nix"
  ];

  # Host-specific nixpkgs configuration
  nixpkgs.hostPlatform = "aarch64-darwin";

  # User configuration
  users.users.${userConfig.name} = {
    home = "/Users/${userConfig.name}";
  };

  # Define the primary user
  system.primaryUser = "reis.holmes";

  # Note: Stylix darwin system-level module has compatibility issues (stylix.icons error)
  # Stylix configuration is handled at the home-manager level instead
  # See home/reis.holmes/reisholmes/default.nix for stylix config

  # Home Manager configuration
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs outputs userConfig;
      nhModules = "${self}/modules/home-manager";
      inherit (inputs) nixgl;
    };
    users.${userConfig.name} = import ../../home/${userConfig.name}/reisholmes;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 5;
}
