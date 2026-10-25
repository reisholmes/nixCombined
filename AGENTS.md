# LLM agent notes for this repo

Before troubleshooting anything in this repo, read `llm-notes/README.md` and the topic files it links.
After resolving a new non-obvious issue here, add a note to the right `llm-notes/` file (or create one) and update the index in `llm-notes/README.md`.

## Layout

- `flake.nix` + `flake.lock`: flake inputs. Keep `flake.lock` tracked; see `llm-notes/flake-eval.md` for why.
- `home/reis/<host>/default.nix`: per-host home-manager config (shell aliases, ssh, systemd units).
- `modules/home-manager/`: shared home-manager modules imported by hosts.
- `modules/darwin/`: macOS (nix-darwin) config.
- Rebuild: `nix_rebuild` alias (defined in the host's `default.nix`). Known pitfalls in `llm-notes/home-manager-rebuild.md`.
- Pre-commit runs alejandra, deadnix, statix; keep them passing.
