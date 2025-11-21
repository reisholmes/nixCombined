{outputs, ...}: {
  # Shared nixpkgs configuration for all home-manager configs
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };
}
