# User-level systemd units (home-manager scope)
#
# Only `systemd.user.*` units live here: standalone home-manager
# manages ~/.config/systemd/user/ only, not root system units.
{...}: {
  imports = [
    ./nix-gc.nix
  ];
}
