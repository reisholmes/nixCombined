# flux9s — Flux GitOps TUI with Catppuccin Mocha theme.
#
# K9s-inspired terminal UI for monitoring Flux resources. Provides
# dependency graphs, reconciliation history, and resource operations
# (suspend, resume, reconcile). Launches in read-only mode by default.
#
# Config lives at ~/.config/flux9s/config.yaml on all platforms.
{pkgs, ...}: {
  home.packages = [pkgs.flux9s];

  home.file.".config/flux9s/config.yaml".source = ../../assets/flux9s/config.yaml;
}
