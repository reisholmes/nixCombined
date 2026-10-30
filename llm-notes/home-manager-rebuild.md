# home-manager rebuild and generation pitfalls

## `nix_rebuild` replayed a stale diff on every rebuild

- **Symptom**: Consecutive `nix_rebuild` runs printed the identical `nvd diff` output (same two store paths, same version bumps), even with zero config changes.
- **Cause**: `nix-env --set` skips creating a new generation when the activation store path is unchanged, so the `home-manager generations` list froze at the last real transition. The old alias diffed the two newest lines of `home-manager generations`, so it re-diffed the same frozen pair (an old nixos-unstable roll) forever.
- **Fix**: The `nix_rebuild` alias in `home/reis/reis-new/default.nix` now captures the current generation before the switch and only runs `nvd diff` if the generation changed; otherwise it prints "No changes (generation unchanged: ...)". (Commit `f09007a`.)
- **Verify**: Two consecutive `nix_rebuild` runs; the second must print "No changes".

## Oneshot systemd unit restarted on every `home-manager switch`

- **Symptom**: "Starting units: nix-gc.service" on every rebuild, not just the scheduled run.
- **Cause**: The unit was a oneshot with `Install.WantedBy = ["default.target"]`. home-manager's `reloadSystemd` activation starts every enabled unit that is not currently active, and a finished oneshot is always inactive, so every switch restarts it.
- **Fix**: Remove `Install.WantedBy` from rarely-run oneshot units and let a timer own the schedule (`Persistent = true` covers missed runs). `nix-gc` is timer-only (Mon 11:00) since commit `f09007a`.
- **Rule**: Never put a rarely-run oneshot into `default.target` under home-manager.

## `nix_rebuild` failed at eval on the nixGL wrapper

- **Symptom**: `nix_rebuild` / `home-manager switch --flake .#reis@reis-new --impure` aborted during evaluation before activation, with a nixGL wrapper failure.
- **Cause**: The `nixgl` flake input builds GL wrappers whose `checkPhase` runs `pcregrep`, which throws against the nixpkgs revision pinned in `flake.lock`. Evaluating any config that sets `targets.genericLinux.nixGL.packages` (our `nixgl = { enable = ...; profile = ...; }` modules) pulls in that wrapper, so the whole config fails to evaluate. Upstream fix is PR "nixGL: use pcre2grep instead of pcregrep" (still open/unmerged).
- **Fix**: Drop the `nixgl` flake input and both wrapper modules (`modules/home-manager/common/nixgl-profiles.nix`, `nixgl-wrapper.nix`) and their usages — ghostty/kitty now use bare `pkgs.ghostty` / `pkgs.kitty`. Both Linux hosts (`reis-new`, `rh-sb3`) set `targets.genericLinux.gpu.enable = true` (home-manager's "fix the host OS" approach). At activation home-manager builds a `non-nixos-gpu` env from nixpkgs (mesa, libglvnd, ...) and prints a one-off `sudo /nix/store/<hash>-non-nixos-gpu/bin/non-nixos-gpu-setup`, which symlinks `/run/opengl-driver` via a tmpfiles.d rule so all Nix packages find GPU drivers without per-app wrapping.
- **Verify**: `home-manager switch --flake .#reis@reis-new --impure --dry-run` exits 0 and prints the `non-nixos-gpu-setup` command. Run that sudo command once (and again after every mesa/driver update); then `ls -l /run/opengl-driver` is a symlink into the store and ghostty renders on the real GPU (not llvmpipe).
- **Rule**: Do not set `targets.genericLinux.nixGL.packages` together with `targets.genericLinux.gpu.enable` — home-manager warns the two are mutually exclusive. To give one app GPU access later, prefer the host-OS approach; do not re-add the nixGL input.

## Profile location

- The home-manager profile generations live in `~/.local/state/nix/profiles/` as `home-manager-<N>-link` symlinks plus a `home-manager` symlink to the newest link. `~/.nix-profile/` holds the activated tree only and contains no `home-manager` profile directory there.

## GC does not affect generation diffs

- The user `nix-gc` unit runs `nix-collect-garbage --delete-older-than 21d` plus `nix-store --optimise`. It only deletes unreachable paths older than 21 days. Profile generations are GC roots; GC can never delete paths that `nvd diff` compares.
- If a diff looks stale or repeats, check which generations are actually being compared (see the `nix_rebuild` note above) before suspecting GC.

## Darwin eval failed: `python3.14-fabric` is broken (via azure-cli)

- **Symptom**: `nix_rebuild` on `reisholmes` aborted at eval with "Refusing to evaluate package 'python3.14-fabric-3.2.3' ... broken". The trace passes through `python3.14-azure-cli-2.91.0` `postFixup`.
- **Cause**: nixpkgs-unstable's `azure-cli` depends on the Python `fabric` package, which is marked broken on python 3.14 at the pinned rev. The `programs.rofi.font` rename warning in the same output is unrelated.
- **Fix**: Remove `azure-cli` from the Nix package list in `modules/home-manager/dev/default.nix`. `az` comes from Homebrew (`modules/darwin/programs/homebrew.nix`). Install the extension by hand: `az extension add --name aks-preview`. Extensions are not Homebrew packages and are not tracked in this repo. On a fresh machine, repeat the manual install, or `az aks` commands fail with "not a known command".
- **Verify**: `nix eval .#darwinConfigurations.reisholmes.system.drvPath` prints a `.drv` path, and `command -v az` prints `/opt/homebrew/bin/az`.
- **Revisit**: When nixpkgs marks `fabric` as working on python 3.14, restore `(azure-cli.withExtensions [azure-cli.extensions.aks-preview])` in the Darwin list and delete this note.
- **Alternatives rejected**: `stable.azure-cli` (2.79.0, a large downgrade), `problems.handlers.fabric.broken = "warn"` (may still fail in fabric's build).
