# 02 - Current workflow of this repo (nixCombined)

Status: Done. Mapped from the local repo on 2026-10-25. Paths are relative to the repo root.

## Overview

- Model: standalone home-manager on Linux, nix-darwin on macOS, no NixOS hosts yet (mkNixosConfiguration exists commented out, nixosConfigurations = {}).
- Structure copied from AlexNabokikh/nix-config per a comment in flake.nix.
- Configured targets: three home-manager profiles (reis@reis-new, reis@rh-sb3, reis.holmes@reisholmes) and one darwin host (reisholmes).

## Layout

```
flake.nix  flake.lock (tracked)  .envrc (use flake)  Makefile  statix.toml
home/reis/reis-new/default.nix        # HM profile
home/reis/rh-sb3/default.nix          # HM profile
home/reis.holmes/reisholmes/default.nix  # HM profile (work user)
hosts/reisholmes/default.nix          # darwin host config
modules/home-manager/{common,dev,programs,systemd,scripts,assets}
modules/darwin/{common,programs,services}
overlays/default.nix
llm-notes/{README.md,flake-eval.md,home-manager-rebuild.md}
.pre-commit-config.yaml  # symlink into the store, generated, gitignored
```

## flake.nix

Inputs: nixpkgs (nixos-unstable), nixpkgs-stable (nixos-25.11), home-manager (follows nixpkgs), nix-darwin (follows nixpkgs), mac-app-util, nixgl (follows nixpkgs), stylix (unstable) + stylix-stable (release-25.11), pre-commit-hooks (follows nixpkgs). All pinned in the tracked flake.lock.

A users attrset holds per-identity data (work vs personal email, git signing public keys, work git remap). Two builder functions do the wiring, both via specialArgs:

```nix
mkDarwinConfiguration = hostname: username:
  nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit inputs outputs hostname self;
      darwinModules = "${self}/modules/darwin";
      userConfig = users.${username};
    };
    modules = [ ./hosts/${hostname} home-manager.darwinModules.home-manager ];
  };

mkHomeConfiguration = system: username: hostname:
  home-manager.lib.homeManagerConfiguration {
    pkgs = import nixpkgs { inherit system; };
    extraSpecialArgs = {
      inherit inputs outputs nixgl;
      userConfig = users.${username};
      nhModules = "${self}/modules/home-manager";
    };
    modules = [ ./home/${username}/${hostname} stylix.homeModules.stylix ];
  };
```

Outputs: darwinConfigurations.reisholmes, the three homeConfigurations, overlays (stable-packages exposing pkgs.stable, pipx-fix setting doCheck = false), checks.<system>.pre-commit-check for x86_64-linux and aarch64-darwin, and devShells.<system>.default whose shellHook installs the git hooks.

Shared modules are imported by string path, not by module object. A host file looks like:

```nix
{ config, nhModules, pkgs, userConfig, ... }: {
  imports = [ "${nhModules}/common" "${nhModules}/dev" ];
  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
  programs.zsh.shellAliases.nix_rebuild = "home-manager switch --flake .#reis@reis-new --impure -b backup && ...";
}
```

Per-host differences: reis-new uses nixgl.profile = "mesa" and KDE monitor aliases. rh-sb3 uses nixgl.profile = "nvidiaPrime". reisholmes (work Mac) splits git config by gitdir for work vs personal repos, disables most stylix targets, and sets sshKeygenProgram.

## Rebuild

The nix_rebuild zsh alias is defined per host. Fixed form (reis-new, commit f09007a):

```sh
old=$(home-manager generations | head -1 | awk "{print $7}"); \
home-manager switch --flake .#reis@reis-new --impure -b backup && \
new=$(home-manager generations | head -1 | awk "{print $7}"); \
if [ "$old" = "$new" ]; then echo "No changes"; else nvd diff "$old" "$new"; fi
```

rh-sb3 still carries the old naive form that re-diffs a frozen generation pair on no-op rebuilds. That is a known gap to fix before any migration work. The darwin host uses sudo darwin-rebuild switch plus nvd diff on /nix/var/nix/profiles/system-*-link. The Makefile mirrors these with home, darwin, nixos, update, gc, check targets.

## Checks and pre-commit

- No CI. The only automated check path is nix flake check, which runs checks.<system>.pre-commit-check.
- Hooks: alejandra 4.1.0 (format), deadnix 1.3.2 (--fail), statix 0.5.8 (config in statix.toml, which disables W04/W20 and sets nix_version = '2.4').
- .pre-commit-config.yaml is a generated symlink into the Nix store. nix develop once installs the hooks via the devShell shellHook. After that they run on git commit.

## llm-notes pitfalls (full text in llm-notes/)

- flake-eval.md: an untracked flake.lock made Nix re-resolve all inputs on every evaluation because the dirty-tree source copy lacked the lockfile. Rule: keep flake.lock tracked. Also never use the --flake path: form in aliases, because it copies .git/, .direnv/, and result into the source and churns the source hash.
- home-manager-rebuild.md: (1) nix-env --set skips creating a generation on no-op rebuilds, so diff the generation captured before and after the switch (fixed in f09007a, reis-new only). (2) A oneshot systemd unit in default.target restarts on every home-manager switch because reloadSystemd starts enabled-but-inactive units. Use timer-only units with Persistent = true, as in systemd/nix-gc.nix. (3) HM profiles live in ~/.local/state/nix/profiles/, not ~/.nix-profile/. (4) GC never deletes GC-rooted generations, so stale diffs are a generation-selection bug, not GC.

## Constraints to respect in any restructure

- flake.lock stays tracked.
- pre-commit trio (alejandra, deadnix, statix) stays passing, wired via devShell shellHook.
- nix_rebuild keeps working. The flake attribute names it references (.homeConfigurations.reis@<host>, .#reisholmes) must not change.
- Makefile targets, statix.toml, .envrc (use flake), overlays.
- No secrets in the repo. SSH private keys live in ~/.ssh, only public signing keys appear in flake.nix.
- AGENTS.md rules: no emojis, Conventional Commits, pre-commit must pass, llm-notes must be updated for new non-obvious fixes.
