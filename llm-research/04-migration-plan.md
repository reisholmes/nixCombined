# 04 - Migration plan (option B: pattern only)

Status: Draft. Executes after 03 is approved. Depends on 01 (pattern) and 02 (current state).

## Target layout

```
flake.nix           # inputs + two-line outputs (flake-parts.mkFlake + import-tree)
flake.lock          # stays tracked
modules/
  parts.nix         # config.systems, pre-commit checks, devShell with hook shellHook
  users.nix         # flake-level option: identity data (emails, signing keys), replaces the users attrset
  shell.nix         # devShells per system
  features/
    git-signing.nix # git SSH signing from user identity
    ssh-config.nix  # per-host ssh config blocks
    stylix.nix      # stylix targets and wallpapers
    nix-gc.nix      # timer-only systemd unit (Persistent = true, never in default.target)
    dev-packages.nix  # replaces modules/home-manager/dev
  home/
    common.nix      # replaces modules/home-manager/common
  hosts/
    reis-new.nix    # host facts + selected features -> .homeConfigurations.reis@reis-new
    rh-sb3.nix      # -> .homeConfigurations.reis@rh-sb3
    reisholmes.nix  # darwin host -> .darwinConfigurations.reisholmes plus its HM profile
overlays/default.nix  # unchanged, still a flake output
```

Old home/, hosts/, and modules/ directories are deleted in the final step, once all four configurations build. The nix_rebuild aliases keep working because the flake attribute names do not change.

## Composition style

Follow the simple style from adumh00man/dendritic-tutorial, not the predicate style from vic/vix: each host file is a module list (`modules = with self.<class>Modules; [ ... ]`) plus optional inline override objects. No `at` predicates. See llm-research/01-dendrix-pattern.md "Fourth example".

## How home-manager fits (the one non-obvious piece)

- Each Linux host module builds its profile with home-manager.lib.homeManagerConfiguration inside the flake-parts tree, following vimjoyer's example at vimjoyer.com/nix/dendritic-home-manager.
- The reisholmes darwin host keeps the home-manager.darwinModules.home-manager module in its darwinSystem call, plus the standalone profile, as today.
- Verify the exact wiring against that example when porting, because the official Dendrix docs do not show it.

## Steps

0. Prereq (standalone, do first): copy the fixed nix_rebuild alias from home/reis/reis-new/default.nix to home/reis/rh-sb3/default.nix. Commit as fix(home): only diff changed generations on rh-sb3.
1. Create branch dendritic.
2. Add inputs: flake-parts (github:hercules-ci/flake-parts) and import-tree (github:vic/import-tree). Commit the lockfile update.
3. Create modules/parts.nix (systems = x86_64-linux and aarch64-darwin, pre-commit checks identical to the current checks attrset, devShell with the hook-installing shellHook) and modules/users.nix (the identity data).
4. Port reis-new (pilot). Port its common/dev imports as feature files it selects. Verify.
5. Port rh-sb3. Verify.
6. Port reisholmes (darwin host plus its HM profile). Verify on the Mac.
7. Delete the old home/, hosts/, and modules/ layout. Update Makefile targets if any paths changed. Update AGENTS.md and write llm-notes/dendritic-migration.md.
8. Final nix flake check on both systems. Commit. Merge the branch.

Do one host per commit. Stop at the first host that fails verification instead of stacking work.

## Verification per host (Definition of Done, per step)

- nix flake check passes (runs alejandra, deadnix, statix via checks).
- nix build .#homeConfigurations.reis@<host> succeeds. For reisholmes, nix build .#darwinConfigurations.reisholmes.
- On the target machine: run nix_rebuild, confirm the nvd diff shows only the expected changes, and confirm no config silently reverted.
- pre-commit runs clean on the commit for that step.

Overall Definition of Done: all four configurations build, nix flake check passes on x86_64-linux and aarch64-darwin, nix_rebuild verified on reis-new and reisholmes (rh-sb3 is remote, verify when next on site), Makefile targets work, and the llm-notes entry is written.

## Rollback

- The whole migration is a branch. Rollback is git checkout <previous-branch>.
- Machines are not touched until nix_rebuild runs on them, so a broken branch breaks nothing until deliberately activated.

## Risks

- home-manager class wiring: the docs do not fully show standalone HM profiles under flake-parts. Mitigation: follow vimjoyer's dendritic-home-manager example exactly.
- nixgl: currently passed via extraSpecialArgs. It becomes a flake-level option or a module argument. Test mesa (reis-new) and nvidiaPrime (rh-sb3) profiles separately.
- stylix: currently imported as stylix.homeModules.stylix per profile. Keep that import inside the stylix feature file so host files stay declarative.
- Ecosystem churn: if the pattern's tooling shifts further (Ren), we own a small module tree, not a lock-in. The pattern is the dependency, the tooling is swappable.

## Effort estimate

- Repo is small (3 hosts, 1 darwin host). Expect 1-2 focused sessions.
- Each host port: about 30-60 minutes of eval-and-fix.
- The darwin host (step 6) needs the Mac available.
