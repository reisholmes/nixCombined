# gaoler (container sandbox for pi)

gaoler is a Go CLI that runs workloads in hardened containers (moby seccomp profile, `cap_drop=ALL`, `no-new-privileges`, non-root user, CPU/memory/pid limits). Repo: https://codeberg.org/KarlGW/gaoler — **not** KarlGQ (that URL 404s; the org is KarlGW). v0.22.0 (2026-10-04), MIT. Not in nixpkgs; no nix image source and no NixOS/home-manager module. A flake can only manage the binary (fetchurl from the [releases](https://codeberg.org/KarlGW/gaoler/releases), sha256 from the release checksums file) plus `~/.gaoler/`.

## gaoler talks Docker, so "podman" means pointing it at podman's Docker API

- **Symptom/decision**: we want podman, not Docker, as the container runtime.
- **Cause**: gaoler is Docker-API-only (go.mod depends on `github.com/moby/moby/client`); "podman" appears nowhere in the README. The single config knob is the top-level `endpoint` field (a unix socket path), auto-populated at first run, default `unix:///var/run/docker.sock`.
- **Fix**: use **rootless** podman. `pkgs.podman` started as the normal user already serves a Docker-compatible API on the per-user socket `$XDG_RUNTIME_DIR/podman/podman.sock` (i.e. `/run/user/<uid>/podman/podman.sock` — check `id -u`). No daemon or systemd unit is needed. Set the literal path in `~/.gaoler/config.json` (gaoler has no `{HOME}`-style interpolation documented for `endpoint`):
  ```json
  { "endpoint": "unix:///run/user/1000/podman/podman.sock" }
  ```
  Do **not** use podman's rootful `/run/podman/podman.sock` — that needs a `podman system service` daemon and root socket access. Do **not** start `podman system service` for the rootless socket; it is created by `podman` itself on first use.
- **Verify**: `curl --unix-socket "$XDG_RUNTIME_DIR/podman/podman.sock" http://d/v1.47/version` returns Docker-engine version JSON (proves the socket speaks the Docker API, which is all gaoler needs). Then `gaoler run --rm <image> echo hi`.
- **Uncertain (verify on first use)**: image *builds* through the Docker API on a rootless podman socket (gaoler builds from `image.tmpl` at `init`), and SELinux labelling, have not been tested here. If build fails, pre-build with `podman build -t gaoler-pi - < image.tmpl-resolved` and point `image.template`/profile at that tag instead.
- **Where in the config**: both podman and gaoler are per-machine, so they go in `home-manager/hosts/<host>.nix` (e.g. `reis-new` or `rh-sb3`), not the shared `home-manager/programs/` tree: `home.packages = [ pkgs.podman pkgs.docker-cli ];` (docker-cli is only for debugging against the socket) plus `home.file."/.gaoler/config.json"` and `home.file."/.gaoler/image.tmpl"` holding the profile above. The pinned home-manager (rev `a1293da`) has **no** `programs.podman` module — only `programs.docker-cli` and `programs.lazydocker` — so do not reach for one.

## Running pi inside a gaoler profile, compatible with our existing pi config

Existing pi config: `home-manager/programs/pi-coding-agent/default.nix` (Jan provider at `http://127.0.0.1:1337/v1`, `apiKey = "$JAN_API_KEY"`, packages pi-subagents / pi-web-access / pi-statusline). All pi state lives under `~/.pi`, so the only mount needed is `~/.pi` — inside the container the same `settings.json`, `models.json`, `auth.json`, sessions, and installed packages apply.

- **Setup**: copy `_examples/coding-harnesses/config.json` + `image.tmpl` from the gaoler repo into `~/.gaoler/`, then `gaoler init && gaoler run --rm --profile pi pi`. Or `gaoler generate command-wrapper --command pi --profile pi` for a `~/.gaoler/bin/pi` wrapper. The repo's `pi` profile verbatim: `{"container": {"volumes": {"{HOME}/.pi": "{HOME}/.pi"}}, "inherit": true}`.
- **Jan provider from the container (resolved 2026-11-17)**: Jan on reis-new is bound to `0.0.0.0:1337`, and the pi-coding-agent program was moved out of the shared `dev` aspect to reis-new only (imported by `modules/hosts/reis-new.nix`) with `baseUrl = "http://192.168.10.10:1337/v1"` (LAN IP, DHCP-reserved). The container reaches Jan over the LAN IP, so no `extraHosts`, second provider entry, or per-container `models.json` is needed. If the IP ever changes, update `home-manager/programs/pi-coding-agent/default.nix`.
- **JAN_API_KEY**: gaoler supports per-profile `container.env` with host-side interpolation: `"env": {"JAN_API_KEY": "{env:JAN_API_KEY}"}` (value forms: literal, `{env:VAR}` read from host env, `{file:/path}`). `envFile` also exists. Profile `env` merges over global `container.env` when `inherit = true`.
- **Gotchas**: the repo's `image.tmpl` hardcodes a **linux-arm64** Go tarball and installs go/uv/opencode/claude too — trim it to just node 24 + `npm install -g --ignore-scripts @earendil-works/pi-coding-agent` for our use; on amd64 hosts the stock template breaks. CWD is auto-mounted as a workspace (`--workspace` / `--no-workspace` to control). uid/gid are fixed at `gaoler init` time (re-init if they change). Detach: Ctrl+P Ctrl+Q; `removeOnHup` removes the container on terminal close. `--memory 8g` (or config `container.memory`) for heavy image builds.
- **Writable-settings interaction**: see `pi-coding-agent.md` — if `mutableSettings = true` is enabled, the container writes runtime state into the same `~/.pi/agent/settings.json` (fine, it's a real file then). Without it, `settings.json` is a root-owned store symlink on the host and pi in the container (running as the user) may fail to write it.
- **Verify**: `gaoler run --rm --profile pi pi -p "Reply with exactly: OK"` returns `OK` (exercises the Jan provider through the container), and `ls ~/.pi/agent/sessions` shows the in-container session persisted.

## Next steps (target host: reis-new; not yet started, 2026-11-17)

- **Goal** — `pi` runs inside a gaoler-hardened podman container using the host's existing `~/.pi` config, on reis-new.
- **Steps**
  1. In `home-manager/hosts/reis-new.nix`: `home.packages = [ pkgs.podman pkgs.docker-cli <gaoler v0.22.0 via fetchurl, sha256 from the release checksums file> ];`
  2. `home.file."/.gaoler/config.json"` in the same file: `endpoint` (literal socket path, e.g. `"unix:///run/user/1000/podman/podman.sock"` — confirm uid with `id -u`), `image.template = "{HOME}/.gaoler/image.tmpl"`, `profiles.pi = { container = { volumes = { "{HOME}/.pi" = "{HOME}/.pi" }; env = { "JAN_API_KEY" = "{env:JAN_API_KEY}" }; }, inherit = true }` (gaoler expands `{HOME}` in volume paths). No extra Jan fix needed — see the resolved section above.
  3. `home.file."/.gaoler/image.tmpl"`: node 24 + `npm install -g --ignore-scripts @earendil-works/pi-coding-agent` only (do not use the repo template as-is; it hardcodes an arm64 Go tarball).
  4. `nix_rebuild`, then `gaoler init` (fixes uid/gid; re-run after any uid change).
- **Done when**
  - `curl --unix-socket "$XDG_RUNTIME_DIR/podman/podman.sock" http://d/v1.47/version` → JSON with `"Name":"Moby"` or docker-engine fields (socket speaks the Docker API).
  - `gaoler run --rm --profile pi pi -p "Reply with exactly: OK"` → `OK` (proves Jan provider + `JAN_API_KEY` work through the container).
  - `ls ~/.pi/agent/sessions` → a new session dir from the in-container run (proves the `~/.pi` mount round-trips state).
