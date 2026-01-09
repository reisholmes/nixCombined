# Darwin (macOS) Modules

This directory contains nix-darwin system configuration modules for macOS hosts.

## Structure

```
modules/darwin/
├── common/           # Shared configuration for all darwin hosts
│   └── default.nix   # Nixpkgs, Nix daemon, fonts, security
├── programs/         # Program-specific configurations
│   └── homebrew.nix  # Homebrew package management
└── services/         # System services and daemons
    └── README.md     # Service module documentation
```

## Common Module

The `common` module provides baseline configuration for all macOS hosts:

- **Nixpkgs**: Allow unfree packages, overlays for stable packages
- **Nix daemon**: Garbage collection (weekly, 21-day retention), automatic optimization
- **Fonts**: System-level fonts (IBM Plex, Nerd Fonts, emoji)
- **Security**: TouchID for sudo authentication

## Programs Module

### Homebrew (`programs/homebrew.nix`)

Declarative Homebrew package management:
- **Taps**: Third-party repositories
- **Brews**: Command-line tools
- **Casks**: GUI applications
- **masApps**: Mac App Store applications

Automatic cleanup removes packages not defined in configuration.

## Services Module

Currently empty. Future service modules may include:
- Window managers (yabai, aerospace)
- Hotkey daemons (skhd)
- Menu bar customization (sketchybar)
- Sync services (syncthing)

## Usage

### In Host Configuration

Import modules in your darwin host (e.g., `hosts/hostname/default.nix`):

```nix
{
  darwinModules,
  ...
}: {
  imports = [
    "${darwinModules}/common"
    "${darwinModules}/programs/homebrew.nix"
  ];

  # Host-specific overrides
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "username";
}
```

### Module Path Injection

The `darwinModules` path is injected in `flake.nix`:

```nix
mkDarwinConfiguration = hostname: username:
  nix-darwin.lib.darwinSystem {
    specialArgs = {
      darwinModules = "${self}/modules/darwin";
      # ...
    };
  };
```

## Adding New Modules

### Program Module

1. Create `modules/darwin/programs/program-name.nix`
2. Add documentation header
3. Import in host: `"${darwinModules}/programs/program-name.nix"`

### Service Module

1. Create `modules/darwin/services/service-name.nix`
2. Configure service options
3. Import in host: `"${darwinModules}/services/service-name.nix"`

## Platform Awareness

Darwin modules are macOS-specific. For cross-platform configurations:

- **Darwin-only**: Use these modules
- **Cross-platform**: Use `modules/home-manager/` with platform conditionals
- **Linux-only**: Create `modules/nixos/` (future)

## Documentation

- nix-darwin options: https://mynixos.com/nix-darwin/options
- nix-darwin manual: https://github.com/LnL7/nix-darwin
- Homebrew module: https://mynixos.com/nix-darwin/options/homebrew
