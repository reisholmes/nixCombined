# Home Manager Modules

This directory contains modular home-manager configurations that are shared across different systems.

## Structure

### Program Modules

Each program module follows this pattern:

```
modules/home-manager/programs/
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
modules/home-manager/common/
├── default.nix           # Main entry point, imports all common modules
├── nixgl-profiles.nix    # NixGL hardware profile configuration (nvidia/mesa/nvidiaPrime)
├── nixgl-wrapper.nix     # Helper function for NixGL wrapping
├── nixpkgs-config.nix    # Nixpkgs overlays and allowUnfree config
├── stylix-common.nix     # Shared Stylix theme and font defaults
└── stylix-host.nix       # Host-specific Stylix configuration (wallpaper, autoEnable)
```

#### Common Module Details

- **`default.nix`**: Entry point that imports all common modules and programs, sets up home environment basics
- **`nixgl-profiles.nix`**: Declarative NixGL configuration for non-NixOS systems. Provides `nixgl.enable` and `nixgl.profile` options with hardware profiles: `nvidia` (enables Vulkan), `mesa` (Intel/AMD graphics), and `nvidiaPrime` (Optimus/Prime laptops with mesa as default and nvidia as offload)
- **`nixgl-wrapper.nix`**: Provides `wrapWithNixGL` helper function that wraps GUI packages with NixGL on Linux and returns them unwrapped on Darwin
- **`nixpkgs-config.nix`**: Configures nixpkgs with overlays and unfree package allowances
- **`stylix-common.nix`**: Defines default fonts (IBM Plex) and color scheme (Catppuccin Mocha) using `lib.mkDefault` for easy per-host overrides
- **`stylix-host.nix`**: Provides host-specific Stylix configuration options. Allows setting `stylix.hostConfig.wallpaper` (path or null to skip wallpaper setup) and `stylix.hostConfig.autoEnable` for automatic application theming

### Development Modules

Development tools and language-specific configurations:

```
modules/home-manager/dev/
└── default.nix    # Development packages and tools
```

### Assets

Shared assets used by multiple modules:

```
modules/home-manager/assets/
├── fastfetch/             # Fastfetch configuration files
├── oh-my-posh/           # Oh-My-Posh theme files
└── stylix/               # Wallpapers and Stylix assets
```

## Usage

### Importing Modules

Modules are typically imported in host-specific configurations:

```nix
# In home/username/hostname/default.nix
imports = [
  "${nhModules}/common"  # Imports all common modules and programs
  "${nhModules}/dev"     # Imports development tools
];
```

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

#### NixGL Configuration (Non-NixOS Linux)

Configure hardware-accelerated graphics on non-NixOS systems:

```nix
# For NVIDIA graphics
nixgl = {
  enable = true;
  profile = "nvidia";
};

# For Intel/AMD graphics
nixgl = {
  enable = true;
  profile = "mesa";
};

# For NVIDIA Optimus/Prime laptops
nixgl = {
  enable = true;
  profile = "nvidiaPrime";
};
```

#### Host-Specific Stylix Configuration

Set wallpapers and theming per host:

```nix
# Set a wallpaper
stylix.hostConfig.wallpaper = ../../../modules/home-manager/assets/stylix/wallpaper_wave_mac.jpg;

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

1. Create a new directory: `modules/home-manager/programs/new-program/`
2. Add `default.nix` with your configuration
3. Import it in `modules/home-manager/common/default.nix`

```nix
imports = [
  # ... other imports
  ../programs/new-program
];
```

## Platform-Specific Configuration

Many modules handle platform differences internally:

- **Darwin (macOS)**: Uses system paths and Homebrew integration where needed
- **Linux**: Uses NixGL wrappers for GUI applications and different font paths

Use `pkgs.stdenv.isDarwin` for conditional logic when needed.

## Special Arguments

Custom arguments passed to all modules:

- `userConfig`: Contains user-specific settings (e.g., `userConfig.name`)
- `nhModules`: Path to home-manager modules directory
- `nixgl`: NixGL packages for Linux GUI support
- `wrapWithNixGL`: Helper function from `nixgl-wrapper.nix`

## Best Practices

1. **DRY Principle**: Extract common configurations to shared modules
2. **Use Defaults**: Apply `lib.mkDefault` for settings that might need host-specific overrides
3. **Document Platform Differences**: Comment when configuration varies by platform
4. **Minimal Dependencies**: Only import what's needed in function signatures
5. **Clear Comments**: Explain non-obvious decisions and link to relevant documentation
