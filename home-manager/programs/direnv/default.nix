# What: Home-manager aspect enabling direnv with nix-direnv.
# Used by: Imported by home-manager/common/default.nix.
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };
}
