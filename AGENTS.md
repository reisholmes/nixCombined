# LLM agent notes for this repo

Before troubleshooting anything in this repo, read `llm-notes/README.md` and the topic files it links.
After resolving a new non-obvious issue here, add a note to the right `llm-notes/` file (or create one) and update the index in `llm-notes/README.md`.

## Layout

- `flake.nix` + `flake.lock`: flake inputs and the two-line `outputs` (flake-parts + import-tree). Keep `flake.lock` tracked; see `llm-notes/flake-eval.md` for why.
- `modules/`: flake-parts modules, auto-loaded by import-tree. Every `.nix` file here is a module.
- `modules/hosts/<host>.nix`: declares that host's flake output (`flake.homeConfigurations.*`, `flake.darwinConfigurations.*`).
- `modules/home/<aspect>.nix`: assigns a home-manager aspect to `flake.modules.homeManager.<aspect>`.
- `home-manager/`: home-manager module content. Not auto-loaded; wrapped by `modules/home/`.
- `home-manager/hosts/<host>.nix`: host-specific home-manager config.
- `darwin/`: nix-darwin module content. Not auto-loaded.
- Rebuild: `nix_rebuild` alias (defined in the host's home-manager file). Known pitfalls in `llm-notes/home-manager-rebuild.md`.
- Pre-commit runs alejandra, deadnix, statix; keep them passing.

## File headers

Every file we author starts with a header comment. It answers two questions and nothing else:

```nix
# What: one line naming the file's job.
# Used by: one line naming the consumer or the loading mechanism.
```

If the file hides a trap, add an optional `# Note:` line. Cap the whole header at 5 lines. If the note needs more, put it in `llm-notes/` and point to it from the header.

Update the header in the same commit as any change that alters the file's role.

Skip the header on generated files (`flake.lock`, `.pre-commit-config.yaml`), JSON, binary assets, and READMEs.
