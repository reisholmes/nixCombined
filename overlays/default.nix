# What: Package overlays: `stable` from nixpkgs-stable, and the pipx check workaround.
# Used by: modules/overlays.nix exposes them as flake.overlays.
{inputs, ...}: {
  # When applied, the stable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.stable'
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  # pipx 1.8.0 had broken tests on nixos-unstable (PEP 508 spacing mismatch).
  # The locked nixpkgs now ships pipx 1.16.6, so this override is a removal
  # candidate; keep doCheck = false until a build without it is verified.
  pipx-fix = _final: prev: {
    pipx = prev.pipx.overridePythonAttrs (_: {
      doCheck = false;
    });
  };
}
