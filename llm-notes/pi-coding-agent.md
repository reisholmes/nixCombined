# pi-coding-agent (pi) notes

## "Warning: No models available" with a local OpenAI-compatible server

- **Symptom**: pi started with `Warning: No models available` and no models could be selected, even though a local OpenAI-compatible server (jan) was running and reachable.
- **Cause**: pi only lists models whose provider has resolvable credentials. `~/.pi/agent/auth.json` was `{}` and no `models.json` existed, so pi had no provider credentials to list from.
- **Fix**: `home-manager/programs/pi-coding-agent/default.nix` now declares `models.providers.jan` (`baseUrl = "http://127.0.0.1:1337/v1"`, `api = "openai-completions"`, `apiKey = "$JAN_API_KEY"` — pi interpolates environment variables in `models.json`) plus `settings.defaultProvider = "jan"` and `settings.defaultModel = "ThinkingCap-Qwen3.8-27B-IQ4_XS.gguf"`. The key comes from a shell variable the user exports outside this repo; never commit it.
- **Verify**: `JAN_API_KEY=... pi --list-models` lists the jan models. `pi -p "Reply with exactly: OK"` returns `OK`.
- **Note**: `models.json` also supports `apiKey = "!command"` (executed per request, uncached). A variant that read the key from `~/.config/opencode/opencode.json` was rejected.

## Issue: 500 "Unexpected reasoning effort high" from the ThinkingCap template

- **Symptom**: every pi request against `jan/ThinkingCap-Qwen3.8-27B-IQ4_XS.gguf` failed with `500 ... Jinja Exception: Unexpected reasoning effort high. Supported types are xhigh (default), medium, and low.` after `defaultThinkingLevel = "high"` was set.
- **Cause**: that GGUF's chat template accepts only `reasoning_effort` values `xhigh`, `medium`, and `low`. Pi's OpenAI-compatible transport sends the pi level name verbatim unless the model declares `thinkingLevelMap`, so `high` and `minimal` reach the template, which raises. Pi also hides `xhigh` and `max` unless the map defines them.
- **Fix**: `home-manager/programs/pi-coding-agent/default.nix` sets `defaultThinkingLevel = "xhigh"` and gives that model `thinkingLevelMap = { low = "low"; medium = "medium"; xhigh = "xhigh"; high = null; minimal = null; }`. Other jan models clamp the global `xhigh` down to `high`, which their templates accept. `off` stays unmapped. Pi then omits `reasoning_effort`, the template falls back to xhigh, and thinking still runs.
- **Verify**: `nix build --no-link .#homeConfigurations."reis@reis-new".activationPackage` succeeds and `jq .providers.jan.models[0].thinkingLevelMap` on the generated `~/.pi/agent/models.json` shows `low`/`medium`/`xhigh` as strings and `high`/`minimal` as null. `pi -p "Reply with exactly: OK"` returns `OK` once the jan backend is up.
- **Note**: the 500 comes from Jan evaluating the model template, not from pi, so the supported values cannot be checked with `pi --list-models`. While the model is unloaded, Jan answers `Proxy request to model failed` instead, which hides the template check.

## Issue: pi runtime state cannot be written to the store-managed `settings.json`

- **Symptom (expected, not yet confirmed)**: pi needs to write runtime state to `~/.pi/agent/settings.json` (e.g. saving a model via Ctrl+S, `pi install` adding to `packages`). home-manager manages `settings`, so the file is a read-only nix-store symlink and such writes fail. As of 2026-11-17 the file is still a store symlink and the user is first testing pi without any option set.
- **Cause**: home-manager's file activation replaces the path with a store symlink on every switch; pi expects a writable file.
- **Possible fix (unverified, not applied)**: add `mutableSettings = true;` to `programs.pi-coding-agent` in `home-manager/programs/pi-coding-agent/default.nix`. Upstream home-manager option; present in the pinned rev `a1293da7dd8e497e08d26173f97e2976b36a31ea`. On activation the symlink becomes a real file pi can write. Declared values win on every activation (a declared `defaultModel` overrides pi's Ctrl+S save). Removing a declaration does not remove it from the file (use `pi uninstall` for packages). pi must be stopped during activation. `models.json` stays immutable.
- **Verify (pending)**: if pi's runtime-state writes fail without the option, enable it and run `home-manager switch --flake .#reis@reis-new --impure -b backup` with pi closed, then check `ls -l ~/.pi/agent/settings.json` is a regular file and the runtime state survives a restart.
