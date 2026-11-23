# gaoler (container sandbox for pi)

gaoler is a Go CLI that runs workloads in hardened containers (moby seccomp profile, `cap_drop=ALL`, `no-new-privileges`, non-root user, CPU/memory/pid limits). Repo: https://codeberg.org/KarlGW/gaoler — **not** KarlGQ (that URL 404s; the org is KarlGW). v0.22.0 (2026-10-04), MIT. Not in nixpkgs; no nix image source and no NixOS/home-manager module. A flake can only manage the binary (fetchurl from the [releases](https://codeberg.org/KarlGW/gaoler/releases), sha256 from the release checksums file) plus `~/.gaoler/`.

## gaoler talks Docker, so "podman" means pointing it at podman's Docker API

- **Symptom/decision**: we want podman, not Docker, as the container runtime.
- **Cause**: gaoler is Docker-API-only (go.mod depends on `github.com/moby/moby/client`); "podman" appears nowhere in the README. The single config knob is the top-level `endpoint` field (a unix socket path), auto-populated at first run, default `unix:///var/run/docker.sock`.
- **Fix**: use **rootless** podman. `pkgs.podman` started as the normal user already serves a Docker-compatible API on the per-user socket `$XDG_RUNTIME_DIR/podman/podman.sock` (i.e. `/run/user/<uid>/podman/podman.sock` — check `id -u`). No daemon or systemd unit is needed. Set the literal path in `~/.gaoler/config.json` (gaoler has no `{HOME}`-style interpolation documented for `endpoint`):
  ```json
  { "endpoint": "unix:///run/user/1000/podman/podman.sock" }
  ```
  Do **not** use podman's rootful `/run/podman/podman.sock` — that needs root socket access. The rootless API socket *is* started by `podman system service`; the earlier "podman creates it on first use" observation only holds for the lifetime of that transient unit (5 min idle) — see the socket-lifetime entry below for the persistent startup command.
- **Verify**: `curl --unix-socket "$XDG_RUNTIME_DIR/podman/podman.sock" http://d/v1.47/version` returns Docker-engine version JSON (proves the socket speaks the Docker API, which is all gaoler needs). Then `gaoler run --rm <image> echo hi`.
- **Verified 2026-11-19**: image builds through the Docker API on a rootless podman socket work, but stock gaoler v0.22.0 **panics** on podman 6's build stream — see the next section. With the patch (built from source), `gaoler init` and `gaoler run` both work end to end.
- **Where in the config**: both podman and gaoler are per-machine, so they go in `home-manager/hosts/<host>.nix` (e.g. `reis-new` or `rh-sb3`), not the shared `home-manager/programs/` tree: `home.packages = [ pkgs.podman pkgs.docker-cli ];` (docker-cli is only for debugging against the socket) plus `home.file."/.gaoler/config.json"` and `home.file."/.gaoler/image.tmpl"` holding the profile above. The pinned home-manager (rev `a1293da`) has **no** `programs.podman` module — only `programs.docker-cli` and `programs.lazydocker` — so do not reach for one.

## Running pi inside a gaoler profile, compatible with our existing pi config

Existing pi config: `home-manager/programs/pi-coding-agent/default.nix` (Jan provider at `http://127.0.0.1:1337/v1`, `apiKey = "$JAN_API_KEY"`, packages pi-subagents / pi-web-access / pi-statusline). All pi state lives under `~/.pi`, so the only mount needed is `~/.pi` — inside the container the same `settings.json`, `models.json`, `auth.json`, sessions, and installed packages apply.

- **Setup**: copy `_examples/coding-harnesses/config.json` + `image.tmpl` from the gaoler repo into `~/.gaoler/`, then `gaoler init && gaoler run --rm --profile pi pi`. Or `gaoler generate command-wrapper --command pi --profile pi` for a `~/.gaoler/bin/pi` wrapper. The repo's `pi` profile verbatim: `{"container": {"volumes": {"{HOME}/.pi": "{HOME}/.pi"}}, "inherit": true}`.
- **Jan provider from the container (resolved 2026-11-17)**: Jan on reis-new is bound to `0.0.0.0:1337`, and the pi-coding-agent program was moved out of the shared `dev` aspect to reis-new only (imported by `modules/hosts/reis-new.nix`) with `baseUrl = "http://192.168.10.10:1337/v1"` (LAN IP, DHCP-reserved). The container reaches Jan over the LAN IP, so no `extraHosts`, second provider entry, or per-container `models.json` is needed. If the IP ever changes, update `home-manager/programs/pi-coding-agent/default.nix`.
- **JAN_API_KEY**: gaoler supports per-profile `container.env` with host-side interpolation: `"env": {"JAN_API_KEY": "{env:JAN_API_KEY}"}` (value forms: literal, `{env:VAR}` read from host env, `{file:/path}`). `envFile` also exists. Profile `env` merges over global `container.env` when `inherit = true`.
- **Gotchas**: the repo's `image.tmpl` hardcodes a **linux-arm64** Go tarball and installs go/uv/opencode/claude too — trim it to just node 24 + `npm install -g --ignore-scripts @earendil-works/pi-coding-agent` for our use; on amd64 hosts the stock template breaks. CWD is auto-mounted as a workspace (`--workspace` / `--no-workspace` to control). uid/gid are fixed at `gaoler init` time (re-init if they change). Detach: Ctrl+P Ctrl+Q; `removeOnHup` removes the container on terminal close. `--memory 8g` (or config `container.memory`) for heavy image builds.
- **Writable-settings interaction**: see `pi-coding-agent.md` — if `mutableSettings = true` is enabled, the container writes runtime state into the same `~/.pi/agent/settings.json` (fine, it's a real file then). Without it, `settings.json` is a root-owned store symlink on the host and pi in the container (running as the user) may fail to write it.
- **Verify**: `gaoler run --rm --profile pi pi -p "Reply with exactly: OK"` returns `OK` (exercises the Jan provider through the container), and `ls ~/.pi/agent/sessions` shows the in-container session persisted.

## Nix packaging pitfalls (hit 2026-11-18 while adding the package to `home-manager/hosts/reis-new.nix`)

- **Symptom**: `home-manager build` fails with `error: attempt to call something which is not a function but a string`.
- **Cause**: Nix has no triple-quote strings; `installPhase = """` parses as the empty string `""`. Use `'' ... ''`.
- **Symptom**: build fails with `unpacker appears to have produced no directories`.
- **Cause**: the release tarball has files at its root (no top-level dir), which the standard unpacker rejects. Set `dontUnpack = true` and run `tar -xf $src --exclude '._*'` in `installPhase`.
- **Symptom**: `error: undefined variable 'docker-cli'` / `pkgs.tar` not found.
- **Cause**: nixpkgs has no `docker-cli` attr (use `pkgs.docker`), and current nixpkgs renamed `tar` to `gnutar`.

## Podman 6 + gaoler 0.22.0 issues (hit 2026-11-19 on reis-new)

- **Symptom**: `podman pull` fails with `config file not found` / `Unknown policy requirement type "disallow"`.
- **Cause**: the nix `podman` package ships **no** `~/.config/containers/policy.json` or `registries.conf`; podman 6's new image engine (go.podman.io/image/v5) only accepts the new requirement types (`reject`, `insecureAcceptAnything`, `signedBy`, `signedBaseLayer`, `sigstoreSigned`) and reads **only** `~/.config/containers/policy.json` (env vars `CONTAINERS_POLICY`/`XDG_CONFIG_HOME` are ignored).
- **Fix**: manage `home.file."/.config/containers/policy.json"` with `{"default":[{"type":"insecureAcceptAnything"}]}` (same default as Docker Desktop). No `registries.conf` needed when images use fully-qualified names (`docker.io/library/node:24-bookworm-slim`). Note `quay.io/library/...` 401s (private/renamed), so Docker Hub it is despite rate limits.
- **Symptom**: `gaoler init` panics with `strings: negative Repeat count` during the image build.
- **Cause**: podman 6's buildah sends `Step 0/0` (BuildKit-style, no step counts) over the Docker API. In `internal/container/service_build.go`, `scanResult` divides by a zero `total` → NaN/negative percentage → `strings.Repeat` panics in the progress bar.
- **Fix**: `patches/gaoler-0.22.0-build-progress-clamp.patch` (clamp to [0,1], NaN guard). The derivation in `home-manager/hosts/reis-new.nix` is now a `buildGoModule` (source archive from Codeberg + patch; `vendorHash` = SRI of the go-modules FOD, read from a deliberate hash-mismatch build). Manual test build: `git clone --branch v0.22.0 https://codeberg.org/KarlGW/gaoler ~/src/gaoler && cd ~/src/gaoler && go build -o gaoler ./cmd/gaoler`.
- **Symptom**: `gaoler run` fails: `Error attaching ... unable to find user reis: no matching entries in passwd file`.
- **Cause**: gaoler runs containers as the host username; podman resolves it against the container `/etc/passwd`. `node:24-bookworm-slim` has no such user (uid 1000 belongs to `node`).
- **Fix**: in `image.tmpl`: `RUN userdel node && groupadd -g 1000 reis && useradd -m -u 1000 -g 1000 reis` (userdel removes the `node` group too; a second `groupdel` fails). uid/gid must match the host so the mounted `~/.pi` stays writable.
- **Trap**: `image.base` only accepts gaoler's supported distros — a custom image name gives `base image not supported`. Custom images must go through `image.template`.
- **Socket lifetime**: the rootless API service is transient (default `podman system service` drops the socket after 5 min idle), and after reboot the `/run/user/1000/podman/` dir is gone. Bring it up with:
  ```sh
  mkdir -p /run/user/1000/podman
  systemd-run --user --unit podman-api podman system service --time=0 unix:///run/user/1000/podman/podman.sock
  ```
  A persistent user unit for this should replace the systemd-run hack before relying on it after reboots.
- **Symptom**: volume mounts are `rw` but every write is `EACCES` as the in-container `reis` (uid 1000).
- **Cause**: rootless podman maps container uid 0 → host uid 1000 and shifts other uids into the subuid range (`/etc/subuid`: 100000–165536), so in-container uid 1000 is a different host identity than the file owner.
- **Fix**: run the container with `--user 0` (container root *is* host `reis` via the identity mapping) and set `HOME` in the profile env — root's default `$HOME` is `/root`, so pi can't find `~/.pi` without it.
- **Symptom**: pi inside the container says `No API key found` even though the key env var is set.
- **Cause**: `~/.pi/agent/models.json` and `settings.json` are `/nix/store` symlinks on the host (home-manager); their targets don't exist in the container, so pi reads nothing.
- **Fix**: add file-level entries to the profile `container.volumes` (docker resolves host symlinks and mounts the real store files); a file entry wins over the enclosing directory entry.
- **Symptom**: `ECONNREFUSED 192.168.10.10:1337` from the container, while the host reaches Jan fine.
- **Cause**: rootless podman's default network (slirp4netns) cannot route back to the host's own LAN IP (no hairpin NAT); even the bridge gateway IP fails.
- **Fix**: `"networks": ["host"]` in the profile `container` config (gaoler passes a single entry straight through as the network mode). Trade-off: the container shares the host network, so gaoler's network isolation is off for this profile.

## Status (2026-11-19: working on reis-new)

- **Done (2026-11-23)**: fully verified end to end. `gaoler run --no-workspace --profile pi --user 0 pi -p "Reply with exactly: OK"` → `OK`, and a fresh session file landed in `~/.pi/agent/sessions/` (Jan + JAN_API_KEY + mount round-trip all work). Requires `--user 0` (uid-mapping issue, see above) and the host-network profile fix.
- **Upstream**: feedback + patch for the build-stream panic is ready for the repo owner (friend of the user); `patches/gaoler-0.22.0-build-progress-clamp.patch` is the diff. Drop the patch and `vendorHash` when a fixed release lands.
