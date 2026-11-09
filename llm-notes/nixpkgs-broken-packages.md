# Broken packages blocking evaluation

## `python3.14-fabric` breaks both darwin configurations

- **Symptom**: `nix eval .#darwinConfigurations.reisholmes.system.drvPath` fails with `Refusing to evaluate package 'python3.14-fabric-3.2.3' ... because it has problems: broken`. The same error appears for `homeConfigurations."reis.holmes@reisholmes"`.
- **Cause**: the pinned nixpkgs marks `python3.14-fabric` broken, and `pipenv` in `home-manager/common/default.nix` pulls it in. It is a nixpkgs regression, not a config error. It reproduces on the pre-migration layout too.
- **Fix**: downgrade the problem to a warning in `home-manager/common/nixpkgs-config.nix`:
  ```nix
  problems.handlers.fabric.broken = "warn";
  ```
- **Verify**: `nix eval .#darwinConfigurations.reisholmes.system.drvPath` prints a derivation path plus an evaluation warning, instead of failing.

## Related

- A package marked broken anywhere in a configuration blocks evaluation of that whole configuration, even if the package is never built.
- When a new breakage appears after a lockfile update, check whether it reproduces at the previous commit before changing config. `git worktree add /tmp/opencode/pre-migration <rev>` gives a clean comparison.
