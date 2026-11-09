# Home Manager Modules

This directory contains modular home-manager configurations that are shared across different systems.

## Structure

### Program Modules

Each program module follows this pattern:

```
home-manager/programs/
├── programName/
│   ├── default.nix          # Main module configuration
│   ├── config/              # Static config files (if needed)
│   └── assets/              # Program-specific assets (optional)
```

**Examples:**

- `lf/default.nix` - Main lf configuration
- `lf/icons` - Icon configuration file for lf
- `git/default.nix` - Main git configuration and delta (enhanced diff viewer) with git integration enabled
- `git/ssh-signing.nix` - Git SSH signing submodule with declarative `programs.git.sshSigning` options

### Common Modules

Shared configuration modules used across all systems:

```
home-manager/common/
├── default.nix           # Main entry point, imports all common modules
├── nixpkgs-config.nix    # Nixpkgs overlays and allowUnfree config
├── stylix-common.nix     # Shared Stylix theme and font defaults
└── stylix-host.nix       # Host-specific Stylix configuration (wallpaper, autoEnable)
```

#### Common Module Details

- **`default.nix`**: Entry point that imports all common modules and programs, sets up home environment basics
- **`nixpkgs-config.nix`**: Configures nixpkgs with overlays and unfree package allowances
- **`stylix-common.nix`**: Defines default fonts (IBM Plex) and color scheme (Catppuccin Mocha) using `lib.mkDefault` for easy per-host overrides
- **`stylix-host.nix`**: Provides host-specific Stylix configuration options. Allows setting `stylix.hostConfig.wallpaper` (path or null to skip wallpaper setup) and `stylix.hostConfig.autoEnable` for automatic application theming

### Development Modules

Development tools and language-specific configurations:

```
home-manager/dev/
└── default.nix    # Development packages and tools
```

### Assets

Shared assets used by multiple modules:

```
home-manager/assets/
├── fastfetch/             # Fastfetch configuration files
├── oh-my-posh/           # Oh-My-Posh theme files
└── stylix/               # Wallpapers and Stylix assets
```

## Usage

### Importing Modules

Host modules select aspects through the flake, they do not import files:

```nix
# In modules/hosts/<host>.nix
modules = [
  config.flake.modules.homeManager.common
  config.flake.modules.homeManager.dev
];
```

The wrappers live in `modules/home/` and point at the content here, for example `modules/home/common.nix` contains `flake.modules.homeManager.common = import ../../home-manager/common;`.

Host-specific config goes in `home-manager/hosts/<host>.nix` and is added to the same `modules` list.

### Overriding Defaults

Most shared configurations use `lib.mkDefault` to allow per-host overrides:

```nix
# Override Stylix fonts on a specific host
stylix.fonts.monospace = {
  package = pkgs.jetbrains-mono;
  name = "JetBrains Mono";
};
```

### Configuration Examples

#### GPU Configuration (Non-NixOS Linux)

Configure hardware-accelerated graphics on non-NixOS systems using home-manager's "fix the host OS" approach (no per-app wrapping):

```nix
targets.genericLinux.gpu.enable = true;
```

At activation home-manager prints a one-off `sudo /nix/store/<hash>-non-nixos-gpu/bin/non-nixos-gpu-setup` command. Run it once (and again whenever the store path changes) so `/run/opengl-driver` points into the Nix store. See the GPU Setup section in the root README and the [upstream home-manager docs](https://nix-community.github.io/home-manager/usage/gpu-non-nixos.html#when-sudo-is-available-fixing-the-host-os).

#### Host-Specific Stylix Configuration

Set wallpapers and theming per host:

```nix
# Set a wallpaper
stylix.hostConfig.wallpaper = ../assets/stylix/wallpaper_wave_mac.jpg;  # relative to home-manager/hosts/

# Skip wallpaper (e.g., on work machines)
stylix.hostConfig.wallpaper = null;

# Disable automatic theming for specific applications
stylix.hostConfig.autoEnable = false;
```

#### Git SSH Signing

Configure SSH commit signing declaratively:

```nix
programs.git.sshSigning = {
  enable = true;
  allowedSigners = [
    {
      email = "user@example.com";
      key = "ssh-ed25519 AAAAC3...";
    }
    {
      email = "work@company.com";
      key = "ssh-ed25519 AAAAC3...";
    }
  ];
  sshKeygenProgram = "/usr/bin/ssh-keygen";  # Optional: use system ssh-keygen on macOS
  forceFileUpdate = true;  # Optional: force update on each rebuild
};
```

### Adding New Program Modules

1. Create a new directory: `home-manager/programs/new-program/`
2. Add `default.nix` with your configuration
3. Import it in `home-manager/common/default.nix`, or expose it as its own aspect in `modules/home/`

```nix
imports = [
  # ... other imports
  ../programs/new-program
];
```

## Platform-Specific Configuration

Many modules handle platform differences internally:

- **Darwin (macOS)**: Uses system paths and Homebrew integration where needed
- **Linux**: GPU access goes through the `targets.genericLinux.gpu` host-OS setup (see root README) plus different font paths

Use `pkgs.stdenv.hostPlatform.isDarwin` for conditional logic when needed.

## Special Arguments

Custom arguments passed to the home-manager modules when the profile is instantiated:

- `userConfig`: user identity data from `config.users.<name>` (for example `userConfig.name`)
- `inputs`: the flake inputs
- `outputs`: the flake outputs, used for `outputs.overlays.*`

`nhModules` no longer exists. The flake modules in `modules/home/` import this directory directly.

## Best Practices

1. **DRY Principle**: Extract common configurations to shared modules
2. **Use Defaults**: Apply `lib.mkDefault` for settings that might need host-specific overrides
3. **Document Platform Differences**: Comment when configuration varies by platform
4. **Minimal Dependencies**: Only import what's needed in function signatures
5. **Clear Comments**: Explain non-obvious decisions and link to relevant documentation
