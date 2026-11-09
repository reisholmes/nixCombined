# What: Sets hosts.homeConfigurations."reis@reis-new" from the homeManager aspects.
# Used by: Auto-loaded by import-tree; published as flake.homeConfigurations for `nix_rebuild`.
{
  self,
  inputs,
  config,
  ...
}: {
  hosts.homeConfigurations."reis@reis-new" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
    extraSpecialArgs = {
      inherit inputs;
      outputs = self;
      userConfig = config.users.reis;
    };
    modules = [
      config.flake.modules.homeManager.common
      config.flake.modules.homeManager.dev
      inputs.stylix.homeModules.stylix
      ../../home-manager/hosts/reis-new.nix
    ];
  };
}
