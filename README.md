# nixCombined

An attempt to combine multiple nix configs

Inspired by: <https://github.com/AlexNabokikh/nix-config>

## Prerequisites

Before getting started, ensure you have the following installed:

- **Git**: Required to clone this repository
- **Nix Package Manager**: [Install Nix](https://nixos.org/download.html) with flakes enabled
- **For macOS users**: [nix-darwin](https://github.com/LnL7/nix-darwin) for system-level configuration
- **For NixOS users**: NixOS 24.11 or later

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
make nixos     # Rebuild NixOS system

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

# NixOS
sudo nixos-rebuild switch --flake .#hostname

# Update flake inputs
nix flake update

# Garbage collect
nix-collect-garbage -d

# Compare generations (requires nvd)
nvd diff /nix/var/nix/profiles/system-{OLD,NEW}-link
```

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
- **flake.nix** - Pre-commit hook configuration in `checks` and `devShells` outputs

### New Machines

When cloning this repo on a new machine, remember to run `nix develop` once to install the pre-commit hooks.

## Quick Start (TLDR)

- Add new home manager name and computer (if using NixOS)
- Install nix on linux
- Bootstrap home manager

```sh
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
nix-shell -p home-manager
home-manager switch --flake .#newuser@newmachine --impure -b backup
```

- From now on you can do:

```sh
home-manager switch --flake .#newuser@newmachine --impure -b backup
```

## Structure

- `flake.nix`: The flake itself, defining inputs and outputs for NixOS, nix-darwin, and Home Manager configurations.
- `hosts/`: NixOS and nix-darwin configurations for each machine
- `home/`: Home Manager configurations for each machine
- `files/`: Miscellaneous configuration files and scripts used across various applications and services
- `modules/`: Reusable platform-specific modules
  - `nixos/`: NixOS-specific modules
  - `darwin/`: macOS-specific modules
  - `home-manager/`: User-space configuration modules (see [modules/home-manager/README.md](modules/home-manager/README.md))
- `flake.lock`: Lock file ensuring reproducible builds by pinning input versions
- `overlays/`: Custom Nix overlays for package modifications or additions

### Key Inputs

- **nixpkgs**: Points to the `nixos-unstable` channel for access to the latest packages
- **nixpkgs-stable**: Points to the `nixos-24.11` channel, providing stable NixOS packages
- **home-manager**: Manages user-specific configurations, following the `nixpkgs` input (release-24.11)
- **hardware**: Optimizes settings for different hardware configurations
- **catppuccin**: Provides global Catppuccin theme integration
- **spicetify-nix**: Enhances Spotify client customization
- **darwin**: Enables nix-darwin for macOS system configuration

## Usage

### Adding a New Machine with a New User

To add a new machine with a new user to your NixOS or nix-darwin configuration, follow these steps:

1. **Update `flake.nix`**:

   a. Add the new user to the `users` attribute set:

   ```nix
   users = {
     # Existing users...
     newuser = {
       avatar = ./files/avatar/face;
       email = "newuser@example.com";
       fullName = "New User";
       gitKey = "YOUR_GIT_KEY";
       name = "newuser";
     };
   };
   ```

   b. Add the new machine to the appropriate configuration set:

   For NixOS:

   ```nix
   nixosConfigurations = {
     # Existing configurations...
     newmachine = mkNixosConfiguration "newmachine" "newuser";
   };
   ```

   For nix-darwin:

   ```nix
   darwinConfigurations = {
     # Existing configurations...
     newmachine = mkDarwinConfiguration "newmachine" "newuser";
   };
   ```

   c. Add the new home configuration:

   ```nix
   homeConfigurations = {
     # Existing configurations...
     "newuser@newmachine" = mkHomeConfiguration "x86_64-linux" "newuser" "newmachine";
   };
   ```

2. **Create System Configuration**:

   a. Create a new directory under `hosts/` for your machine:

   ```sh
   mkdir -p hosts/newmachine
   ```

   b. Create `default.nix` in this directory:

   ```sh
   touch hosts/newmachine/default.nix
   ```

   c. Add the basic configuration to `default.nix`:

   For NixOS:

   ```nix
   { inputs, hostname, nixosModules, ... }:
   {
     imports = [
       inputs.hardware.nixosModules.common-cpu-amd
       ./hardware-configuration.nix
       "${nixosModules}/common"
       "${nixosModules}/programs/hyprland"
     ];

     networking.hostName = hostname;
   }
   ```

   For nix-darwin:

   ```nix
   { config, pkgs, ... }:
   {
     # Add machine-specific configurations here
   }
   ```

   d. For NixOS, generate `hardware-configuration.nix`:

   ```sh
   sudo nixos-generate-config --show-hardware-config > hosts/newmachine/hardware-configuration.nix
   ```

3. **Create Home Manager Configuration**:

   a. Create a new directory for the user's host-specific configuration:

   ```sh
   mkdir -p home/newuser/newmachine
   touch home/newuser/newmachine/default.nix
   ```

   b. Add basic home configuration:

   ```nix
   { nhModules, ... }:
   {
     imports = [
       "${nhModules}/common"
       "${nhModules}/programs/neovim"
       "${nhModules}/services/waybar"
     ];
   }
   ```

4. **Building and Applying Configurations**:

   a. Commit new files to git:

   ```sh
   git add .
   ```

   b. Build and switch to the new system configuration:

   For NixOS:

   ```sh
   sudo nixos-rebuild switch --flake .#newmachine
   ```

   For nix-darwin (requires Nix and nix-darwin installation first):

   ```sh
   darwin-rebuild switch --flake .#newmachine
   ```

   c. Build and switch to the new Home Manager configuration:

> [!IMPORTANT]
> On fresh systems, bootstrap Home Manager first:

```sh
nix-shell -p home-manager
home-manager switch --flake .#newuser@newmachine
```

After this initial setup, you can rebuild configurations separately and home-manager will be available without additional steps

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
- [modules/home-manager/README.md](modules/home-manager/README.md) - Home Manager module documentation

### System Modules (in `modules/nixos/`)

- `common/`: Common system configurations
- `desktop/gnome.nix`: GNOME desktop environment
- `desktop/hyprland.nix`: Hyprland window manager
- `programs/corectrl.nix`: CoreCtrl for AMD GPU management
- `programs/steam.nix`: Steam gaming platform
- `services/tlp.nix`: Laptop power management

## Host-Specific Notes

For machine-specific setup instructions and configuration notes, see the README in each host directory:
- [hosts/reis-new/README.md](hosts/reis-new/README.md) - CachyOS setup notes

## Changelog

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
- `flake.nix:137-166` - Pre-commit checks and devShell configuration
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
- Comprehensive configuration examples in [modules/home-manager/README.md](modules/home-manager/README.md)
- Module documentation with usage patterns and platform notes
- Improved DRY principles through declarative options

**Documentation:**
- Updated `modules/home-manager/README.md` with new module details
- Added configuration examples for all new features
- Module headers with usage instructions

**Migration Guide:** See [modules/home-manager/README.md](modules/home-manager/README.md) Configuration Examples section for detailed usage of new declarative patterns.

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
