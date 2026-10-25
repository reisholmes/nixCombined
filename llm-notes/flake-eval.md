# Flake evaluation banners and input drift

## Untracked `flake.lock` re-resolves all inputs on every evaluation

- **Symptom**: Any flake command in this repo (`nix flake metadata .`, builds, `home-manager switch`) prints the full "Added input ..." list for all ~50 inputs, and `flake.lock` gets a new mtime on every evaluation. Every ghostty/direnv tab opened in the repo directory re-evaluates the whole flake (`.envrc` uses `use flake`).
- **Cause**: Nix evaluates a dirty git tree by copying only tracked files into the store as a `-source` path. With `flake.lock` in `.gitignore`, the store source copy contains no lock file, so Nix silently re-resolves every input to latest on every evaluation and writes the lock as an unread byproduct. Nothing is actually pinned.
- **Fix**: Keep `flake.lock` tracked. If it is ever ignored again: `git add -f flake.lock` and remove the entry from `.gitignore` (original fix: commit `e34c4ed`). All machines in this repo share one set of input pins; update inputs deliberately with `nix flake update`.
- **Verify**: `nix flake metadata .` prints no "updating lock file" banner, and `flake.lock` mtime is unchanged after the evaluation.

## Related

- Do not switch aliases from `--flake .#...` to `--flake path:`. The `path:` form copies the directory including untracked files (`.git/`, `.direnv/`, `result`), so the source hash churns on every git commit or direnv reload.
