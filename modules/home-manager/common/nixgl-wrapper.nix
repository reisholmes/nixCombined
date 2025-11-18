{
  config,
  pkgs,
  lib,
  ...
}: {
  # Helper function to wrap packages with NixGL on Linux
  # On Darwin, packages are returned unwrapped
  # Usage: wrapWithNixGL pkgs.kitty
  _module.args.wrapWithNixGL = pkg:
    if pkgs.stdenv.isDarwin
    then pkg
    else config.lib.nixGL.wrap pkg;
}
