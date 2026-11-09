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
    };
  };
}
