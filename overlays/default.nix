{inputs, ...}: {
  # When applied, the stable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.stable'
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  # pipx 1.8.0 has broken tests on nixos-unstable (PEP 508 spacing mismatch).
  # doCheck = false mirrors the fix already on nixpkgs/master; remove once
  # nixos-unstable picks up a version with fixed tests.
  pipx-fix = _final: prev: {
    pipx = prev.pipx.overridePythonAttrs (_: {
      doCheck = false;
    });
  };
}
