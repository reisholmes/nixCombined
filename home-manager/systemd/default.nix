# What: Aggregates user-level systemd units for home-manager.
# Used by: Imported by home-manager/common/default.nix.
# Note: Only systemd.user.* units belong here. Rarely-run oneshots must be timer-only, see llm-notes/home-manager-rebuild.md.
{...}: {
  imports = [
    ./nix-gc.nix
  ];
}
