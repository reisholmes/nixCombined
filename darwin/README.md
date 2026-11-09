# Darwin (macOS) Modules

This directory contains nix-darwin system configuration modules for macOS hosts.

## Structure

```
darwin/
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

Cleanup is off. If you remove a package from `homebrew.nix`, a rebuild leaves it installed. The `onActivation.cleanup` comment in `programs/homebrew.nix` says why, and how to list packages that are not in the configuration.

## Services Module

Currently empty. Future service modules may include:
- Window managers (yabai, aerospace)
- Hotkey daemons (skhd)
- Menu bar customization (sketchybar)
- Sync services (syncthing)

## Usage

### In Host Configuration

Import modules in the darwin host module, `darwin/hosts/<host>.nix`:

```nix
{
  userConfig,
  inputs,
  ...
}: {
  imports = [
    ../common
    ../programs/homebrew.nix
  ];

  # Host-specific overrides
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "username";
}
```

### Wiring in the flake

`modules/hosts/reisholmes.nix` builds the system and passes the module in:

```nix
hosts.darwinConfigurations.reisholmes =
  inputs.nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit inputs;
      outputs = self;
      userConfig = config.users."reis.holmes";
    };
    modules = [
      ../../darwin/hosts/reisholmes.nix
      inputs.home-manager.darwinModules.home-manager
    ];
  };
```

## Adding New Modules

### Program Module

1. Create `darwin/programs/program-name.nix`
2. Add the two-line header
3. Import it in the host: `../programs/program-name.nix`

### Service Module

1. Create `darwin/services/service-name.nix`
2. Configure service options
3. Import it in the host: `../services/service-name.nix`

## Platform Awareness

Darwin modules are macOS-specific. For cross-platform configurations:

- **Darwin-only**: Use these modules
- **Cross-platform**: Use `home-manager/` with platform conditionals
- **Linux-only**: A future `nixos/` content directory, wired through `modules/hosts/` like `darwin/` is (do not put content under `modules/` directly; import-tree auto-loads it as a flake-parts module)

## Documentation

- nix-darwin options: https://mynixos.com/nix-darwin/options
- nix-darwin manual: https://github.com/LnL7/nix-darwin
- Homebrew module: https://mynixos.com/nix-darwin/options/homebrew
