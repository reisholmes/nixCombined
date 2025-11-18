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

**Example:**
- `lf/default.nix` - Main lf configuration
- `lf/icons` - Icon configuration file for lf

### Common Modules

Shared configuration modules used across all systems:

```
modules/home-manager/common/
├── default.nix           # Main entry point, imports all common modules
├── nixpkgs-config.nix    # Nixpkgs overlays and allowUnfree config
├── stylix-common.nix     # Shared Stylix theme and font defaults
└── nixgl-wrapper.nix     # Helper function for NixGL wrapping
```

#### Common Module Details

- **`default.nix`**: Entry point that imports all common modules and programs, sets up home environment basics
- **`nixpkgs-config.nix`**: Configures nixpkgs with overlays and unfree package allowances
- **`stylix-common.nix`**: Defines default fonts (IBM Plex) and color scheme (Catppuccin Mocha) using `lib.mkDefault` for easy per-host overrides
- **`nixgl-wrapper.nix`**: Provides `wrapWithNixGL` helper function that wraps GUI packages with NixGL on Linux and returns them unwrapped on Darwin

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
