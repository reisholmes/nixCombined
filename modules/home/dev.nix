# What: Flake-parts wrapper assigning the `dev` aspect to the homeManager class.
# Used by: Auto-loaded from modules/ by import-tree; host modules select flake.modules.homeManager.dev.
_: {
  flake.modules.homeManager.dev = import ../../home-manager/dev;
}
