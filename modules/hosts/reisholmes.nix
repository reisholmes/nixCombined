# What: Sets hosts.darwinConfigurations.reisholmes and the matching homeConfiguration.
# Used by: Auto-loaded by import-tree; published as flake outputs for `nix_rebuild` and `make darwin`.
{
  self,
  inputs,
  config,
  ...
}: let
  user = config.users."reis.holmes";
in {
  hosts.darwinConfigurations.reisholmes = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit inputs;
      outputs = self;
      userConfig = user;
    };
    modules = [
      ../../darwin/hosts/reisholmes.nix
      inputs.home-manager.darwinModules.home-manager
    ];
  };

  hosts.homeConfigurations."reis.holmes@reisholmes" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {system = "aarch64-darwin";};
    extraSpecialArgs = {
      inherit inputs;
      outputs = self;
      userConfig = user;
    };
    modules = [
      config.flake.modules.homeManager.common
      config.flake.modules.homeManager.dev
      inputs.stylix.homeModules.stylix
      ../../home-manager/hosts/reisholmes.nix
    ];
  };
}
