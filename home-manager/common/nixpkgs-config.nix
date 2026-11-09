# What: nixpkgs overlays and config applied inside home-manager.
# Used by: Imported by home-manager/common/default.nix.
{outputs, ...}: {
  # Shared nixpkgs configuration for all home-manager configs
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
      outputs.overlays.pipx-fix
    ];
    config = {
      allowUnfree = true;
      # python3.14-fabric is marked broken in the pinned nixpkgs and pipenv pulls it,
      # which fails evaluation of both darwin configs. Downgrade to a warning.
      problems.handlers.fabric.broken = "warn";
    };
  };
}
