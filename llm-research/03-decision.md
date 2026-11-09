# 03 - Decision: move this repo to the Dendritic pattern

Status: Done. Option B approved by the user on 2026-11-09. Depends on 01 (pattern) and 02 (current state).

## Options

- A. Stay as is (AlexNabokikh/nix-config style: builder functions + specialArgs + string-path imports).
- B. Adopt the Dendritic pattern only: flake-parts + import-tree, per-file modules, hosts as data. No Dendrix input.
- C. Adopt the pattern plus the Dendrix registry (add the dendrix input, consume or contribute community trees).

## What changes in B, concretely

- flake.nix shrinks to inputs plus a two-line outputs. The users attrset, mkDarwinConfiguration, and mkHomeConfiguration disappear.
- Identity data (emails, signing keys) becomes a flake-level option instead of a specialArgs argument. This removes our heaviest use of the specialArgs anti-pattern (userConfig, nhModules, darwinModules, inputs, outputs, self, hostname all flow through specialArgs today).
- modules/home-manager/common and /dev become auto-loaded feature files instead of explicit string-path imports.
- Host files keep the same flake attribute names (.homeConfigurations.<user>@<host>, .darwinConfigurations.reisholmes), so nix_rebuild and the Makefile keep working unchanged.
- New NixOS hosts later become a new class in the same module tree instead of a separate mkNixosConfiguration.

## Pros of B (or C) over A

- Removes specialArgs/extraSpecialArgs threading, which the pattern docs call an anti-pattern and which is our biggest current wart.
- Auto module loading: dropping a file into modules/ enables a feature. No import lists to maintain as hosts grow.
- Feature-centric layout: git signing, ssh config, stylix, nix-gc become named features that any host can opt into. Today that logic is split across common/, dev/, and per-host files.
- homeManager and darwin are first-class classes, so our exact mix (standalone HM + one darwin host) is a supported shape, and the reserved NixOS slot fills in naturally.
- Two-line flake.nix plus per-file modules is easier for LLM agents to navigate, and this repo is heavily LLM-driven (AGENTS.md, llm-notes).

## Cons of B (or C) over A

- Real migration cost: rewrite three host files, the darwin host, and restructure modules/. Small repo, so this is a restructure, not a rewrite.
- Learning curve for flake-parts module composition and the homeManager class wiring. The docs have gaps (no platform matrix).
- Ecosystem churn: the flagship repo (vic/vix) already moved to "Ren". We would be adopting a pattern whose reference implementation is migrating.
- No CI to catch breakage during or after migration. Only nix flake check and manual rebuilds.
- Risk concentrates on the live machines: a bad module can break a working host on the next rebuild. Mitigated by per-host verification and a git branch (see 04).

## Cons of staying (A)

- specialArgs threading grows with every new host and every new shared value.
- Import lists are manual and host-centric, the inverse of how we actually think about features.
- The layout depends on one person's convention. Nobody else's tools or templates line up with it.

## Cons of C over B (why the registry does not fit us yet)

- We have one user and three hosts. There is nothing cross-repo to consume or share.
- Community trees carry "no guarantees of things working", and only one repo is explicitly registered.
- Every registry aspect is a remote dependency on someone's personal repo, removed when unmaintained.
- Revisit C when a second machine of a type we want to share, or a NixOS host, makes consuming a community aspect worthwhile.

## Decision criteria

- Reuse need: low today (one user). The pattern helps even here because features, not hosts, are the unit.
- Future NixOS: the flake already reserves it. The pattern makes that slot cheaper.
- Registry need: none today.
- Reversibility: the migration is a branch. Rollback is git checkout of the previous branch. Nothing destructive.

## Recommendation (approved 2026-11-09)

Adopt option B: the Dendritic pattern without the Dendrix registry.

- Pilot on reis-new (it already has the fixed nix_rebuild alias), then rh-sb3, then reisholmes (darwin) last since it runs on a different OS and needs the Mac for verification.
- Keep all operational constraints from 02: tracked flake.lock, pre-commit trio, nix_rebuild attribute names, Makefile, statix.toml, .envrc.
- Fix the rh-sb3 nix_rebuild alias first, as a standalone commit before any migration work.
- Treat C (registry) as a later opt-in, not part of this migration.
