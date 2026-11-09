# What: nix-darwin system module for reisholmes: platform, users, home-manager wiring.
# Used by: modules/hosts/reisholmes.nix passes it to nix-darwin.lib.darwinSystem.
{
  pkgs,
  outputs,
  userConfig,
  inputs,
  ...
}: {
  # Import darwin modules for common configurations
  imports = [
    ../common
    ../programs/homebrew.nix
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
    # Move a colliding file to <name>.backup-<timestamp> instead of aborting activation.
    # A timestamp, not backupFileExtension: a fixed <name>.backup aborts activation the
    # second time the same file collides, because the earlier backup is still there.
    # Home Manager runs this command once per colliding file, with the file path as $1.
    backupCommand = "${pkgs.writeShellScript "hm-backup" ''
      ${pkgs.coreutils}/bin/mv -- "$1" "$1.backup-$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
    ''}";
    extraSpecialArgs = {
      inherit inputs outputs userConfig;
    };
    # Stylix system-level darwin module has compatibility issues, so it runs in home-manager.
    sharedModules = [
      inputs.stylix.homeModules.stylix
      outputs.modules.homeManager.common
      outputs.modules.homeManager.dev
    ];
    users.${userConfig.name} = import ../../home-manager/hosts/reisholmes.nix;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 5;
}
