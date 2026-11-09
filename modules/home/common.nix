# What: Flake-parts wrapper assigning the shared `common` aspect to the homeManager class.
# Used by: Auto-loaded from modules/ by import-tree; host modules select flake.modules.homeManager.common.
_: {
  flake.modules.homeManager.common = import ../../home-manager/common;
}
