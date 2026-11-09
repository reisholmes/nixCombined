# LLM troubleshooting notes

Lessons learned debugging this repo. New notes use the format: **Symptom / Cause / Fix / Verify**.
Keep notes as facts, file paths, and exact commands.
When you resolve a new non-obvious issue, append a note to the right file (or create a new one). Add a link to any new file in this index.

## Index

- [Flake evaluation banners and input drift](flake-eval.md)
- [home-manager rebuild and generation pitfalls](home-manager-rebuild.md)
- [Dendritic Nix migration handover](dendritic-handover.md) — not a troubleshooting note; handover state for the in-progress migration, full research in `llm-research/`
- [Dendritic migration pitfalls](dendritic-migration.md) — flake-parts output merging, `flake.modules`, auto-loading under `modules/`
