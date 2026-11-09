# What: Flake-wide settings: systems, the flake.modules option, pre-commit checks, devShell.
# Used by: Auto-loaded by import-tree. Everything else builds on it.
{inputs, ...}: {
  imports = [inputs.flake-parts.flakeModules.modules];

  systems = ["x86_64-linux" "aarch64-darwin"];

  perSystem = {
    system,
    config,
    ...
  }: {
    # Pre-commit hooks for code quality
    checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
      src = ../.;
      hooks = {
        # Nix formatter
        alejandra.enable = true;
        # Nix linter (configured via statix.toml to ignore style-only warnings)
        statix = {
          enable = true;
          settings = {
            config = "${../.}/statix.toml";
          };
        };
        # Find and remove unused code
        deadnix.enable = true;
      };
    };

    # Development shell with pre-commit hooks
    # Run 'nix develop' once to install git hooks, then they run automatically on commit
    devShells.default = (import inputs.nixpkgs {inherit system;}).mkShell {
      inherit (config.checks.pre-commit-check) shellHook;
      buildInputs = config.checks.pre-commit-check.enabledPackages;
    };
  };
}
