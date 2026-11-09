# Dendritic migration pitfalls

## `flake.modules` does not exist in flake-parts

- **Symptom**: `nix eval` fails with `The option 'flake.modules' is defined multiple times while it's expected to be unique. No option has been declared for this flake output attribute`.
- **Cause**: flake-parts does not declare `flake.modules`. Its `flake` option is a freeform attrset whose element type is `unique raw`, so any undeclared output attribute can only be defined once.
- **Fix**: `imports = [inputs.flake-parts.flakeModules.modules];` in `modules/parts.nix`.
- **Verify**: `nix eval .#modules.homeManager.common` evaluates, and `nix flake check` stops reporting the conflict.

## Two host modules cannot both set `flake.homeConfigurations`

- **Symptom**: Adding a second host module gives `The option 'flake.homeConfigurations' is defined multiple times while it's expected to be unique`.
- **Cause**: flake-parts merges only at the top level of `flake`. `flake.homeConfigurations` is one output attribute, and its type is `unique raw`, so nested keys from different modules do not merge.
- **Fix**: declare a real option and publish it once. `modules/outputs.nix` declares `options.hosts.homeConfigurations` and `options.hosts.darwinConfigurations` as `attrsOf raw`, then sets `config.flake.homeConfigurations = config.hosts.homeConfigurations`. Host modules set `hosts.homeConfigurations.<name>`.
- **Verify**: `nix eval .#homeConfigurations."reis@reis-new".activationPackage.drvPath` and the same for `reis@rh-sb3` both succeed.

## Every `.nix` file under `modules/` is auto-loaded

- **Symptom**: Adding a home-manager module file under `modules/` fails with unknown options such as `programs.zsh`.
- **Cause**: `import-tree ./modules` loads every file under that root as a flake-parts module. Home-manager and nix-darwin module content is not flake-parts module content.
- **Fix**: keep reusable home-manager and nix-darwin content outside `modules/`, in `home-manager/` and `darwin/`. `modules/home/<aspect>.nix` wraps it with `flake.modules.homeManager.<aspect> = import ../../home-manager/<aspect>;`.
- **Verify**: `nix eval .#modules.homeManager.common` returns a function, not an evaluation error.
