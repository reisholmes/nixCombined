# What: Exposes the package overlays as the flake `overlays` output.
# Used by: Auto-loaded by import-tree; home-manager modules read them through `outputs.overlays`.
{inputs, ...}: {
  flake.overlays = import ../overlays {inherit inputs;};
}
