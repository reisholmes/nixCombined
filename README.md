# nixCombined

An attempt to combine multiple nix configs, structured with the Dendritic pattern (flake-parts + import-tree).

Inspired by: <https://github.com/AlexNabokikh/nix-config>

## Prerequisites

Before getting started, ensure you have the following installed:

- **Git**: Required to clone this repository
- **Nix Package Manager**: [Install Nix](https://nixos.org/download.html) with flakes enabled
- **For macOS users**: [nix-darwin](https://github.com/LnL7/nix-darwin) for system-level configuration
- **For NixOS users**: NixOS 25.11 or later (reserved for future use — this flake currently has no NixOS machines)

Enable experimental features if not already configured:

```sh
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
```

## Quick Commands

Common operations for managing your configuration:

### Using Makefile (Recommended)

```bash
# Rebuild configurations
make darwin    # Rebuild Darwin (macOS) system
make home      # Rebuild Home Manager (Linux or standalone macOS)
make nixos     # Rebuild NixOS system (reserved — no NixOS machines yet)

# Maintenance
make update    # Update all flake inputs
make gc        # Garbage collect old generations
make check     # Validate flake configuration

# Bootstrap new machines
make bootstrap-darwin  # Install nix-darwin and configure
make bootstrap-home    # Install home-manager and configure

# Get help
make help      # Show all available commands
```

### Manual Commands

```bash
# Darwin (macOS)
darwin-rebuild switch --flake .#reisholmes

# Home Manager (Linux)
home-manager switch --flake .#reis@reis-new --impure -b backup

# NixOS (reserved for future use — nixosConfigurations is currently empty)
sudo nixos-rebuild switch --flake .#hostname

# Update flake inputs
nix flake update

# Garbage collect
nix-collect-garbage -d

# Compare generations (requires nvd)
nvd diff /nix/var/nix/profiles/system-{OLD,NEW}-link
```

### `nix_rebuild` Alias

Every host defines a `nix_rebuild` shell alias, managed via `programs.zsh.shellAliases` in `home-manager/hosts/<host>.nix`. It captures the current generation, rebuilds, captures the new one, then prints `nvd diff` between them. If the rebuild created no new generation it prints `No changes` instead of re-diffing a stale pair:

- **Linux hosts** (`reis@reis-new`, `reis@rh-sb3`): `home-manager switch` + nvd diff
- **macOS** (`reis.holmes@reisholmes`): `darwin-rebuild switch` + nvd diff

So on any of the managed machines, `nix_rebuild` is the one-liner for "rebuild me and show what changed".

## GPU Setup (non-NixOS Linux)

Both Linux hosts (`reis-new`, `rh-sb3`) set `targets.genericLinux.gpu.enable = true`. This is home-manager's "fix the host OS" GPU approach: instead of wrapping each GUI app with nixGL, home-manager builds a `non-nixos-gpu` environment (mesa, libglvnd, ...) and installs a tmpfiles.d rule that symlinks `/run/opengl-driver` into it. Every Nix package then finds the GPU drivers through that single symlink.

**Why not nixGL**: the `nixgl` flake input builds GL wrappers whose `checkPhase` runs `pcregrep`, which no longer exists in the pinned nixpkgs, so any config referencing it failed to evaluate. The nixGL input and wrapper modules were removed; see `llm-notes/home-manager-rebuild.md` for the full write-up.

### One-off `sudo` setup

At activation, home-manager prints a one-off command:

```sh
sudo /nix/store/<hash>-non-nixos-gpu/bin/non-nixos-gpu-setup
```

Run it once with `sudo`. It writes the tmpfiles.d rule so `/run/opengl-driver` points into the Nix store. Re-run it whenever the `non-nixos-gpu` store path changes, i.e. after nixpkgs or mesa updates. Without it, GPU apps silently fall back to llvmpipe software rendering.

Verify after running it:

```sh
ls -l /run/opengl-driver   # must be a symlink into /nix/store
LIBGL_DEBUG=1 kitty        # must report the real GPU, not llvmpipe
```

Upstream documentation: [home-manager, GPU drivers on non-NixOS systems (fixing the host OS)](https://nix-community.github.io/home-manager/usage/gpu-non-nixos.html#when-sudo-is-available-fixing-the-host-os).

## Development & Code Quality

This repository includes automated code quality checks using pre-commit hooks:

### Pre-commit Hooks

The following checks run automatically on every commit:
- **alejandra** - Nix code formatter
- **statix** - Nix linter (configured via `statix.toml`)
- **deadnix** - Detects unused Nix code

### Setup

On first clone or when hooks aren't installed:

```bash
nix develop
```

This automatically installs the git hooks. They will then run on every commit.

### Manual Checks

Run all checks manually without committing:

```bash
nix flake check
```

### Configuration

- **statix.toml** - Configures statix to ignore style-only warnings (W04, W20)
- **modules/parts.nix** - Pre-commit hook configuration in the `checks` and `devShells` outputs

### New Machines

When cloning this repo on a new machine, remember to run `nix develop` once to install the pre-commit hooks.

## Structure

- `flake.nix`: inputs plus a two-line `outputs`. Evaluation is handed to flake-parts, which loads `modules/` with import-tree.
- `modules/`: flake-parts modules, auto-loaded, one concern per file.
  - `modules/hosts/<host>.nix`: declares a machine's flake outputs.
  - `modules/home/<aspect>.nix`: exposes a home-manager aspect as `flake.modules.homeManager.<aspect>`.
  - `modules/parts.nix`: systems, pre-commit checks, devShell.
  - `modules/users.nix`: user identity data (emails, public signing keys).
  - `modules/outputs.nix`: publishes host outputs once, because flake-parts merges only top-level flake outputs.
- `home-manager/`: home-manager module content, wrapped by `modules/home/` (see [home-manager/README.md](home-manager/README.md)).
- `home-manager/hosts/<host>.nix`: host-specific home-manager config.
- `darwin/`: nix-darwin module content (see [darwin/README.md](darwin/README.md)).
- `docs/`: guides such as package version pinning, plus per-machine notes under `docs/hosts/`.
- `llm-notes/`: troubleshooting notes in Symptom/Cause/Fix/Verify form, indexed in `llm-notes/README.md`.
- `llm-research/`: research, decision, and migration docs for the dendritic pattern.
- `flake.lock`: Lock file ensuring reproducible builds by pinning input versions
- `overlays/`: Custom Nix overlays for package modifications or additions

### Key Inputs

- **nixpkgs**: Points to the `nixos-unstable` channel for access to the latest packages
- **nixpkgs-stable**: Points to the `nixos-25.11` channel, providing stable packages (used by `overlays/`)
- **home-manager**: Manages user-specific configurations, following the `nixpkgs` input
- **nix-darwin**: Enables nix-darwin for macOS system configuration
- **mac-app-util**: Building and managing macOS apps
- **stylix**: Theming framework (colors, fonts, wallpapers) applied via home-manager. `stylix-stable` pins the `release-25.11` branch
- **pre-commit-hooks**: Code quality hooks (alejandra, statix, deadnix) used by the `checks` and `devShells` outputs
- **flake-parts**: Builds the flake outputs from modules. It replaces the hand-written `outputs` function.
- **import-tree**: Loads every `.nix` file under `modules/` as a flake-parts module.

## Usage

### Quick Start (TLDR)

- Add the user and the host (see [Adding a New Machine](#adding-a-new-machine))
- Install Nix on Linux, or Nix plus nix-darwin on macOS
- Bootstrap home-manager

```sh
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
nix-shell -p home-manager
home-manager switch --flake .#newuser@newmachine --impure -b backup
```

> [!NOTE]
> `nix-shell -p home-manager` pulls the *latest unstable* home-manager, not the version pinned by the flake. This is only for bootstrapping a fresh machine so that the `home-manager` command exists. Afterwards every rebuild re-uses the flake-pinned home-manager (installed by the first `switch`), so the two converge.

- From now on you can do:

```sh
home-manager switch --flake .#newuser@newmachine --impure -b backup
```

### Adding a New Machine

Today the flake has three hosts: `reis-new` and `rh-sb3` (standalone Home Manager on Linux) and `reisholmes` (nix-darwin plus Home Manager on macOS). There are no NixOS hosts yet. A NixOS host would follow the same shape with a `hosts.nixosConfigurations` option.

1. **Add the user (only for a new person)** in `modules/users.nix`:

   ```nix
   newuser = {
     fullName = "New User";
     name = "newuser";
     email = "newuser@example.com";
     signingKeyPub = "ssh-ed25519 AAAA...";
   };
   ```

2. **Add the host-specific home-manager config** in `home-manager/hosts/<machine>.nix`. Start from an existing host and keep the two-line header:

   ```nix
   # What: Host-specific home-manager config for <machine>.
   # Used by: modules/hosts/<machine>.nix.
   {userConfig, ...}: {
     programs.home-manager.enable = true;
     home.stateVersion = "25.11";
   }
   ```

3. **Declare the flake output** in `modules/hosts/<machine>.nix`:

   ```nix
   {self, inputs, config, ...}: {
     hosts.homeConfigurations."newuser@newmachine" =
       inputs.home-manager.lib.homeManagerConfiguration {
         pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
         extraSpecialArgs = {
           inherit inputs;
           outputs = self;
           userConfig = config.users.newuser;
         };
         modules = [
           config.flake.modules.homeManager.common
           config.flake.modules.homeManager.dev
           inputs.stylix.homeModules.stylix
           ../../home-manager/hosts/newmachine.nix
         ];
       };
   }
   ```

   For macOS, also set `hosts.darwinConfigurations.<machine>` the way `modules/hosts/reisholmes.nix` does, and add the matching home configuration.

   Every `.nix` file under `modules/` is loaded automatically. To add a shared aspect, create `modules/home/<aspect>.nix` containing `flake.modules.homeManager.<aspect> = import ../../home-manager/<aspect>;`. Keep home-manager and nix-darwin module content outside `modules/`, in `home-manager/` and `darwin/`.

4. **Building and Applying Configurations**:

   a. Commit new files to git:

   ```sh
   git add .
   ```

   b. On macOS, build and switch the system configuration (requires Nix and nix-darwin installed first):

   ```sh
   darwin-rebuild switch --flake .#newmachine
   ```

   There is no NixOS host yet. When one is added, `sudo nixos-rebuild switch --flake .#newmachine` follows the same shape.

   c. Build and switch to the new Home Manager configuration:

> [!IMPORTANT]
> On fresh systems, bootstrap Home Manager first:

```sh
nix-shell -p home-manager
home-manager switch --flake .#newuser@newmachine
```

> [!NOTE]
> `nix-shell -p home-manager` installs the latest unstable home-manager, not the flake-pinned one. It's only needed once so the `home-manager` command exists. From then on the flake-pinned version takes over.

After this initial setup, you can rebuild configurations separately and home-manager will be available without additional steps.

## Updating Flakes

To update all flake inputs to their latest versions:

```sh
nix flake update
```

## Advanced Package Management

### Pinning Specific Package Versions

Sometimes you need a specific version of a package that isn't in your current nixpkgs channels. See the comprehensive guide:

**[Package Version Pinning Documentation](docs/package-version-pinning.md)**

This guide covers:
- Finding specific package versions across nixpkgs history
- Multiple search tools (web and CLI)
- Implementing version pins in your flake
- Alternative approaches (overrides, custom derivations)
- Best practices and troubleshooting

**Example use case:** Install `cowsay 3.8.3` when both unstable and stable channels only have `3.8.4`.

## Package Installation Strategy

This configuration uses different package managers based on the use case:

### Nix Home Manager (Primary)
- **CLI tools and utilities**: All command-line tools (e.g., `git`, `kubectl`, `terraform`)
- **Development tools**: Language servers, formatters, linters
- **Cross-platform applications**: Apps that work consistently across Linux and macOS

### Homebrew (macOS Only)
- **macOS-native GUI applications**: Apps that integrate deeply with macOS (e.g., `raycast`, `deskflow`)
- **Apps requiring native installers**: Software where Home Manager packaging is problematic
- **Preference**: Use sparingly; prefer Home Manager when possible for reproducibility

### System Package Managers (Linux)
- **Distribution-specific tools**: `yay` on CachyOS for AUR packages
- **System services**: Applications requiring systemd integration (e.g., `coolercontrol`, `proton-pass`)
- **Hardware-specific drivers**: DKMS modules and kernel-level tools

### General Rule
When in doubt, try Home Manager first. Fall back to system package managers only when:
1. The package isn't available in nixpkgs
2. The package requires deep system integration (systemd services, kernel modules)
3. The package has complex runtime dependencies that don't work well with Home Manager's user-space approach

## Modules

For detailed module documentation and structure, see:
- [home-manager/README.md](home-manager/README.md) - Home Manager module documentation
- [darwin/README.md](darwin/README.md) - nix-darwin module documentation

## Host-Specific Notes

For machine-specific setup instructions and configuration notes, see the README in each host directory:
- [docs/hosts/reisholmes/README.md](docs/hosts/reisholmes/README.md) - macOS setup notes
- [docs/hosts/reis-new/README.md](docs/hosts/reis-new/README.md) - CachyOS setup notes
- [docs/hosts/rh-sb3/README.md](docs/hosts/rh-sb3/README.md) - Linux Mint setup notes

## Changelog

### 2026-11-09 - Dendritic pattern: flake-parts + import-tree

**Breaking Changes:**

- **Layout** - `flake.nix` now only declares inputs and a two-line `outputs`. Everything else lives in `modules/`, which import-tree loads automatically. Home-manager content moved from `modules/home-manager/` to `home-manager/`, and nix-darwin content from `modules/darwin/` to `darwin/`.
- **Host configs** - `home/<user>/<host>/default.nix` became `home-manager/hosts/<host>.nix`, and each host's flake output is now declared in `modules/hosts/<host>.nix`.
- **`nhModules` removed** - Host files no longer import `"${nhModules}/common"`. Hosts select aspects through `config.flake.modules.homeManager.<aspect>`.
- **Host notes** - `hosts/<host>/` moved to `docs/hosts/<host>/`.
- **File headers** - Every authored file now starts with `# What:` / `# Used by:` lines. See `AGENTS.md`.

**Why:** see `llm-research/03-decision.md` (decision) and `llm-research/04-migration-plan.md` (procedure).

---

### 2026-10-28 - NixGL removed, host-OS GPU approach

**Breaking Changes:**

- **NixGL removed** - The `nixgl` flake input and the `nixgl-profiles.nix` / `nixgl-wrapper.nix` modules are gone. The wrapper `checkPhase` (pcregrep) broke evaluation against current nixpkgs. ghostty and kitty now use bare `pkgs.ghostty` / `pkgs.kitty`.
- **GPU** - Linux hosts set `targets.genericLinux.gpu.enable = true` (rh-sb3 is iGPU/mesa only, no NVIDIA offload). After a rebuild that changes the `non-nixos-gpu` store path, run the printed one-off `sudo non-nixos-gpu-setup` command. See the GPU Setup section above.

---

### 2025-01-23 - Pre-commit Hooks Integration

**New Features:**
- **Pre-commit hooks** - Automated code quality checks on every commit
  - Nix formatter (alejandra)
  - Nix linter (statix)
  - Unused code detection (deadnix)
- **Development shell** - `nix develop` installs git hooks automatically
- **statix.toml** - Configuration to disable style-only warnings (manual_inherit_from, repeated_keys)
- **Code quality improvements** - Cleaned up formatting and removed unused parameters across codebase

**Setup:**
```bash
nix develop  # Run once to install hooks
```

**Files:**
- `flake.nix:134-163` - Pre-commit checks and devShell configuration
- `statix.toml` - Statix linter configuration
- `.gitignore` - Ignores auto-generated pre-commit configs

---

### 2025-01-23 - Home Manager Module Refactoring

**Breaking Changes:**

1. **NixGL Configuration** - Moved to declarative profile-based system
   ```nix
   # Before:
   targets.genericLinux.nixGL = {
     packages = nixgl.packages;
     defaultWrapper = "nvidia";
     vulkan.enable = true;
   };

   # After:
   nixgl = {
     enable = true;
     profile = "nvidia";  # Options: nvidia, mesa, nvidiaPrime
   };
   ```

2. **Stylix Host Configuration** - New host-specific options module
   ```nix
   # Before:
   stylix.image = ./wallpaper.jpg;
   stylix.autoEnable = true;

   # After:
   stylix.hostConfig.wallpaper = ./wallpaper.jpg;
   stylix.hostConfig.autoEnable = true;
   # Note: Set wallpaper to null to skip (e.g., on work machines)
   ```

3. **Git SSH Signing** - Declarative submodule for commit signing
   ```nix
   # Before:
   home.file.".ssh/allowed_signers".source = allowedSignersFile;
   programs.git.settings.gpg.format = "ssh";
   programs.git.settings.gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";

   # After:
   programs.git.sshSigning = {
     enable = true;
     allowedSigners = [
       { email = "user@example.com"; key = "ssh-ed25519 ..."; }
       { email = "work@company.com"; key = "ssh-ed25519 ..."; }
     ];
     sshKeygenProgram = "/usr/bin/ssh-keygen";  # Optional: macOS native
     forceFileUpdate = true;  # Optional: force update on each rebuild
   };
   ```

**New Features:**
- Three new shared modules in `modules/home-manager/common/`:
  - `nixgl-profiles.nix` - Hardware profile abstraction for NixGL
  - `stylix-host.nix` - Host-specific theming options
  - `git/ssh-signing.nix` - SSH signing configuration submodule
- Comprehensive configuration examples in [home-manager/README.md](home-manager/README.md)
- Module documentation with usage patterns and platform notes
- Improved DRY principles through declarative options

**Documentation:**
- Updated `home-manager/README.md` with new module details
- Added configuration examples for all new features
- Module headers with usage instructions

**Migration Guide:** See [home-manager/README.md](home-manager/README.md) Configuration Examples section for detailed usage of new declarative patterns.

---

### 2025-01-23 - Documentation & Tooling Improvements

**New Features:**
- **Makefile** - Convenience commands for common operations:
  - Short commands: `make darwin`, `make home`, `make update`, `make gc`, `make check`
  - Automatic hostname/user detection
  - Built-in nvd diff output after rebuilds
  - Bootstrap commands for new machines
  - Backwards-compatible legacy command aliases
- **Quick Commands** - README section with common rebuild/maintenance commands
- **Module Headers** - Self-documenting comments in key module files
- **Changelog** - This section for tracking breaking changes and migrations

## References

### Example Configurations

<https://github.com/juspay/nixos-unified-template>

<https://github.com/srid/nixos-unified>

<https://github.com/dustinlyons/nixos-config>

<https://www.reddit.com/r/NixOS/comments/yk4n8d/hostspecific_settings_different_approaches/iurkkxv/>

<https://github.com/mwdavisii/nyx/blob/main/flake.nix>

<https://github.com/jevy/home-manager-nix-config>

<https://github.com/mcdonc/.nixconfig>

<https://github.com/TLATER/dotfiles>

<https://github.com/srid/nixos-config>

<https://github.com/Misterio77/nix-starter-configs>

### Literature

<https://callistaenterprise.se/blogg/teknik/2025/04/10/nix-flakes/>
