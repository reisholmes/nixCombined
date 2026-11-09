# What: Declares host output options and publishes them as flake outputs.
# Used by: Auto-loaded by import-tree. Host modules set hosts.homeConfigurations.<name>.
{
  config,
  lib,
  ...
}: {
  options.hosts.homeConfigurations = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = {};
    description = "Home-manager configurations, published as flake.homeConfigurations.";
  };

  options.hosts.darwinConfigurations = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = {};
    description = "nix-darwin configurations, published as flake.darwinConfigurations.";
  };

  config.flake.homeConfigurations = config.hosts.homeConfigurations;
  config.flake.darwinConfigurations = config.hosts.darwinConfigurations;
}
