# Dendritic Nix migration handover

Status at 2026-11-09: option B approved. Work is on branch `dendritic`. reis-new and rh-sb3 ported and evaluated. reisholmes still on the old layout and missing from the flake outputs until ported.
All background lives in `llm-research/` (self-contained, re-read those before any implementation work).

## What we did

- Researched the Dendritic pattern: official Dendrix docs (`https://dendrix.denful.dev`), four example repos (`jackjohn7/nixconf`, `denful/dendrix`, `vic/vix`, `git.voidarc.co.uk/adumh00man/dendritic-tutorial`), and vimjoyer's videos/code (`vimjoyer.com/nix/dendritic`, `vimjoyer.com/nix/dendritic-home-manager`).
- Mapped this repo's current workflow (flake shape, hosts, rebuild aliases, pre-commit, pitfalls).
- Decided: adopt the Dendritic **pattern only** (flake-parts + import-tree), skip the Dendrix **registry**.

Key facts (details in the linked docs):

- "Dendritic" = the pattern: every `modules/*.nix` is a flake-parts module, auto-loaded via `github:vic/import-tree`. "Dendrix" = the community registry on top. Separate things; we use only the pattern.
- home-manager and nix-darwin are first-class classes in the pattern, so our exact mix (standalone HM profiles + one darwin host) is a supported shape.
- Our current wart: `specialArgs`/`extraSpecialArgs` threading (`userConfig`, `nhModules`, `darwinModules`, `inputs`, `outputs`, `self`, `hostname`). The pattern docs call `specialArgs` an anti-pattern; in the new layout this data becomes a flake-level option.
- Complication: `vic/vix` (flagship example) moved off flake-parts to "Ren" (`github:vic/ren`). Ecosystem is churning. The registry only explicitly registers `vic-vix`.
- Composition style chosen: the simple host-file-as-module-list style from `dendritic-tutorial`, not the `at`-predicate style from `vic/vix`. The tutorial is NixOS-only (no home-manager or darwin), so vimjoyer's `dendritic-home-manager` remains the reference for our HM-class wiring.
- No CI exists. Checks = `nix flake check` (alejandra, deadnix, statix) + pre-commit via `nix develop` shellHook.

## Files

- `llm-research/README.md` — index of research docs.
- `llm-research/01-dendrix-pattern.md` — what the pattern is, terms, minimal flake, getting started, sources.
- `llm-research/02-current-workflow.md` — this repo as of 2026-10-25: flake, hosts, `nix_rebuild`, checks, constraints.
- `llm-research/03-decision.md` — options A (stay) / B (pattern) / C (pattern + registry), recommendation B, **pending user sign-off**.
- `llm-research/04-migration-plan.md` — target layout, steps, definition of done, rollback.

## Next steps

0. Done 2026-11-09: user accepted option B in `llm-research/03-decision.md`.
1. Done 2026-11-09, uncommitted: copied the fixed `nix_rebuild` alias from `home/reis/reis-new/default.nix` to `home/reis/rh-sb3/default.nix`. `nix flake check` passes.
2. Done: on branch `dendritic`.
3. Done: added `flake-parts` and `import-tree` inputs.
4. Done: `modules/parts.nix`, `modules/users.nix`, `modules/overlays.nix`. `flake.modules` needs `inputs.flake-parts.flakeModules.modules`.
5. Done: ported `reis-new`. Old content moved out of `modules/` to `home-manager/` and `darwin/` because import-tree auto-loads every file under `modules/`. Verified by `nix eval .#homeConfigurations.reis@reis-new.activationPackage.drvPath` and `nix flake check --system x86_64-linux`.
6. Done: ported `rh-sb3`. Verified by `nix eval .#homeConfigurations.reis@rh-sb3.activationPackage.drvPath` and `nix flake check`.
7. Pending: port `reisholmes` (darwin + its HM profile). Needs the Mac.
8. Pending: delete old `home/` and `hosts/` dirs, update Makefile/AGENTS.md, write `llm-notes/dendritic-migration.md`, `nix flake check` on both systems, merge.

One host per commit. Stop at the first host that fails verification. Rollback = `git checkout` of the previous branch; machines are untouched until `nix_rebuild` is run on them.

## Constraints that must survive the migration

- `flake.lock` stays tracked (see `flake-eval.md`).
- `nix flake check` and pre-commit (alejandra, deadnix, statix, config in `statix.toml`) keep passing.
- Flake attribute names `homeConfigurations.reis@<host>` and `darwinConfigurations.reisholmes` must not change: the `nix_rebuild` aliases and `Makefile` depend on them.
- Never use `--flake path:` in aliases (source-hash churn, see `flake-eval.md`).
- systemd units: timer-only with `Persistent = true`, never in `default.target` (see `home-manager-rebuild.md`).
- `AGENTS.md`: no emojis, Conventional Commits, pre-commit must pass, new non-obvious fixes get an `llm-notes/` entry.
