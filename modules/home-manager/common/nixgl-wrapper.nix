{
  config,
  pkgs,
  ...
}: {
  # Helper function to wrap packages with NixGL on Linux
  # On Darwin, packages are returned unwrapped
  # Usage: wrapWithNixGL pkgs.kitty
  _module.args.wrapWithNixGL = pkg:
    if pkgs.stdenv.isDarwin
    then pkg
    else if config.lib ? nixGL && config.lib.nixGL ? wrap
    then config.lib.nixGL.wrap pkg
    else throw "nixGL not available - ensure nixGL input is configured for Linux hosts";
}
