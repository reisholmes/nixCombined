# User-level systemd units (home-manager scope)
#
# Only `systemd.user.*` units live here: home-manager manages
# ~/.config/systemd/user/ and cannot manage root system units.
{...}: {
  imports = [
    ./nix-gc.nix
  ];
}
