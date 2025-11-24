# Darwin Services Modules

This directory contains nix-darwin service configuration modules.

## Purpose

Service modules manage background daemons, LaunchAgents, and system services on macOS.

## Examples

Potential service modules:
- **yabai.nix** - Window management service
- **skhd.nix** - Hotkey daemon
- **aerospace.nix** - Tiling window manager
- **sketchybar.nix** - Custom menu bar
- **syncthing.nix** - File synchronization

## Usage

Import service modules in your darwin host configuration:

```nix
imports = [
  darwinModules.services.serviceName
];
```

Then configure the service:

```nix
services.serviceName = {
  enable = true;
  # ... service-specific options
};
```

## Documentation

- nix-darwin services options: https://mynixos.com/nix-darwin/options/services
- LaunchAgents documentation: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/
