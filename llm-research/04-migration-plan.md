# 04 - Migration plan (option B: pattern only)

Status: Draft. Executes after 03 is approved. Depends on 01 (pattern) and 02 (current state).

## Target layout

```
flake.nix           # inputs + two-line outputs (flake-parts.mkFlake + import-tree)
flake.lock          # stays tracked
modules/            # flake-parts modules only, auto-loaded by import-tree
  parts.nix         # systems, imports inputs.flake-parts.flakeModules.modules, pre-commit checks, devShell
  users.nix         # flake-level option `users` (identity data)
  overlays.nix      # flake.overlays output
  outputs.nix       # declares hosts.homeConfigurations/darwinConfigurations, publishes them once as flake outputs
  home/
    common.nix      # flake.modules.homeManager.common = import ../../home-manager/common
    dev.nix         # flake.modules.homeManager.dev
  hosts/
    reis-new.nix    # flake.homeConfigurations."reis@reis-new" (ported)
    rh-sb3.nix      # pending
    reisholmes.nix  # pending (darwin host plus its HM profile)
home-manager/       # HM module content, NOT auto-loaded, imported by the modules/home wrappers
  hosts/reis-new.nix  # host-specific HM config (moved from home/reis/reis-new/default.nix)
darwin/             # nix-darwin module content, NOT auto-loaded
overlays/default.nix  # unchanged, still a flake output
```

Rule: every `.nix` file under `modules/` becomes a flake-parts module. Reusable home-manager and nix-darwin module content therefore lives outside `modules/`, in `home-manager/` and `darwin/`.

`flake.modules` is not a built-in flake-parts option. `modules/parts.nix` imports `inputs.flake-parts.flakeModules.modules` to declare it. `nix flake check` then prints `warning: unknown flake output 'modules'`, which is cosmetic.

## Composition style

Follow the simple style from adumh00man/dendritic-tutorial, not the predicate style from vic/vix: each host file is a module list (`modules = with self.<class>Modules; [ ... ]`) plus optional inline override objects. No `at` predicates. See llm-research/01-dendrix-pattern.md "Fourth example".

## How home-manager fits (verified for reis-new)

- A host module builds its profile with `home-manager.lib.homeManagerConfiguration` inside the flake-parts tree, then assigns it to `hosts.homeConfigurations."<user>@<host>"`. `modules/outputs.nix` publishes that option once as `flake.homeConfigurations`.
- Why the indirection: flake-parts merges only the top level of `flake`, and each output attribute is `unique raw`. Two host modules setting `flake.homeConfigurations.<name>` directly is an evaluation error. See `llm-notes/dendritic-migration.md`.
- HM module content is wrapped, not rewritten: `modules/home/common.nix` sets `flake.modules.homeManager.common = import ../../home-manager/common`.
- `extraSpecialArgs` survives at the HM instantiation boundary only (`inputs`, `outputs = self`, `userConfig` from `config.users`). Inside the HM modules nothing changed. Removing it entirely means rewriting the ~20 HM module files to take options, which is a separate, later cleanup.
- `nhModules` is gone. The one real user was `home-manager/programs/nix-search-tv`, now a relative path. Host imports are gone because the flake module selects the aspects.
- The reisholmes darwin host keeps the `home-manager.darwinModules.home-manager` module in its darwinSystem call, plus the standalone profile, as before.

## Steps

0. Done 2026-11-09: rh-sb3 `nix_rebuild` alias fixed (commit `435ff18`).
1. Done: branch `dendritic`.
2. Done: `flake-parts` and `import-tree` inputs added.
3. Done: `modules/parts.nix`, `modules/users.nix`, `modules/overlays.nix` created.
4. Done: reis-new ported. Verified with `nix eval .#homeConfigurations.reis@reis-new.activationPackage.drvPath` and `nix flake check --system x86_64-linux`.
5. Done: rh-sb3 ported. Verified by `nix eval .#homeConfigurations.reis@rh-sb3.activationPackage.drvPath` and `nix flake check`. A real `nix_rebuild` on that machine is still owed.
6. Done: reisholmes ported. Both `darwinConfigurations.reisholmes` and `homeConfigurations."reis.holmes@reisholmes"` evaluate. A real rebuild on the Mac is still owed.
7. Done: host notes moved from `hosts/` to `docs/hosts/`, READMEs updated to the new layout. Remaining: rebuild verification on the real machines, then merge.

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
