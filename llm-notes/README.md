# LLM troubleshooting notes

Lessons learned debugging this repo. New notes use the format: **Symptom / Cause / Fix / Verify**.
Keep notes as facts, file paths, and exact commands.
When you resolve a new non-obvious issue, append a note to the right file (or create a new one). Add a link to any new file in this index.

## Index

- [Flake evaluation banners and input drift](flake-eval.md)
- [home-manager rebuild and generation pitfalls](home-manager-rebuild.md)
- [Dendritic Nix migration handover](dendritic-handover.md) — not a troubleshooting note; migration record, merged into `main` 2026-11-09, full research in `llm-research/`
- [Dendritic migration pitfalls](dendritic-migration.md) — flake-parts output merging, `flake.modules`, auto-loading under `modules/`
- [Homebrew activation pitfalls](homebrew.md) — cleanup resets tap trust, a removed formula hides the cask that replaced it
