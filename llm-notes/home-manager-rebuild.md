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

## Profile location

- The home-manager profile generations live in `~/.local/state/nix/profiles/` as `home-manager-<N>-link` symlinks plus a `home-manager` symlink to the newest link. `~/.nix-profile/` holds the activated tree only and contains no `home-manager` profile directory there.

## GC does not affect generation diffs

- The user `nix-gc` unit runs `nix-collect-garbage --delete-older-than 21d` plus `nix-store --optimise`. It only deletes unreachable paths older than 21 days. Profile generations are GC roots; GC can never delete paths that `nvd diff` compares.
- If a diff looks stale or repeats, check which generations are actually being compared (see the first note) before suspecting GC.
