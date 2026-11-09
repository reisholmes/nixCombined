# llm-research: Dendritic Nix migration

Research docs for migrating this repo from the AlexNabokikh/nix-config style to the Dendritic Nix pattern (flake-parts + import-tree).

Written 2026-10-25 from research passes on the official Dendrix docs, four example repos (jackjohn7/nixconf, denful/dendrix, vic/vix, adumh00man/dendritic-tutorial), and a local map of this repo. Each file is self-contained: key facts are inlined, not just linked, so a compacted session can re-read a file without re-researching.

## Files

| File | Topic | Status |
|---|---|---|
| `01-dendrix-pattern.md` | What the Dendritic pattern is, core terms, getting started, vimjoyer's content | Done |
| `02-current-workflow.md` | How this repo works today (flake, hosts, rebuild, checks) | Done |
| `03-decision.md` | Pros/cons per option, recommendation: pattern only, no registry | Done (option B approved 2026-11-09) |
| `04-migration-plan.md` | Stepwise plan, pilot host, verification, rollback | Draft (executing) |

Status legend: Done = complete, stable. Draft = will change during execution.

## TL;DR for future sessions

- "Dendritic" is the pattern (flake-parts + import-tree, every modules/*.nix is a module). "Dendrix" is the community registry on top. They are separate; we adopt the pattern only.
- Our repo: 3 standalone home-manager profiles + 1 nix-darwin host, no NixOS hosts yet. Layout copied from AlexNabokikh/nix-config. We thread userConfig/nhModules/inputs through specialArgs, which the Dendritic docs call an anti-pattern.
- Recommendation: restructure to flake-parts + import-tree, pilot host reis-new, keep pre-commit and nix_rebuild, skip the Dendrix registry for now.
- Pre-existing gap to fix first, independent of migration: rh-sb3's nix_rebuild alias still has the stale-generation-diff bug fixed for reis-new in commit f09007a.
