# nixCombined

An attempt to combine multiple nix configs

Copied from the much more talented: <https://github.com/AlexNabokikh/nix-config>

## TLDR

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

## Notes on things I discovered along the way

### Reis-New - CachyOS

- Install the gaming packages `sudo pacman -S cachyos-gaming-meta cachyos-gaming-applications`

- Switching to zsh using the Nix profile directory on CachyOs broke all Dolphin
  applications and mime links. Instead I did

```bash
chsh -s /usr/bin/zsh
```

- Trying to manage systemd services on home manager sucks.
CoolerControl required a service so instead I
installed it through [yay on
CachyOs](https://docs.coolercontrol.org/installation/arch.html)

- To get fan control working on CoolerControl I had to add the following to the
  end of /boot/refind_linux.conf:

```text
acpi_enforce_resources=lax
```

- To get T_Sensor values, I added support to the [asus-ec-sensors](https://github.com/zeule/asus-ec-sensors)
repository and when this is pushed to mainline we can just add the
asus-ec-sensors nix package to reis-new/default.nix. To install the module run
the following:

```
sudo pacman -S yay
yay dkms
(select - 2 cachyos/dkms 3.2.1-2 (46.7 KiB 151.2 KiB))

sudo LLVM=true make modules
sudo LLVM=true make modules_install
sudo LLVM=true make dkms_configure
sudo LLVM=true make dkms
```

- Whilst Home-Manager does provide packages for 1Password, if you want to use
it as your ssh key manager it won't work properly. Just [install it manually](https://support.1password.com/install-linux/#arch-linux)

- Sound control (for EQ) is setup via [EasyEffects](https://github.com/wwmm/easyeffects) with: `yay easyeffects` and `yay lsp-plugins-lv2`
When prompted for:

```
Sync Explicit (1): lsp-plugins-lv2-1.2.21-1.1
resolving dependencies...
:: There are 17 providers available for lv2-host:
:: Repository cachyos-extra-v3
   1) ardour  2) carla  3) ecasound  4) guitarix  5) jalv  6) muse  7) qtractor
:: Repository extra
   8) ardour  9) audacity  10) carla  11) ecasound  12) element  13) guitarix  14) jalv  15) muse  16) qtractor
   17) reaper
```

I selected option 1

- RGB Control is setup through OpenRGB: `yay openrgb` and selecting from
`cachyos-extra-v3`

------

To get up and running:

## Structure

- `flake.nix`: The flake itself, defining inputs and outputs for NixOS, nix-darwin, and Home Manager configurations.
- `hosts/`: NixOS and nix-darwin configurations for each machine
- `home/`: Home Manager configurations for each machine
- `files/`: Miscellaneous configuration files and scripts used across various applications and services
- `modules/`: Reusable platform-specific modules
  - `nixos/`: NixOS-specific modules
  - `darwin/`: macOS-specific modules
  - `home-manager/`: User-space configuration modules
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

## Modules and Configurations

### System Modules (in `modules/nixos/`)

- `common/`: Common system configurations
- `desktop/gnome.nix`: GNOME desktop environment
- `desktop/hyprland.nix`: Hyprland window manager
- `programs/corectrl.nix`: CoreCtrl for AMD GPU management
- `programs/steam.nix`: Steam gaming platform
- `services/tlp.nix`: Laptop power management

### Home Manager Modules (in `modules/home-manager/`)

1. **Core Utilities**:

   - `common/`: Cross-platform base configuration
   - `programs/git.nix`: Git version control
   - `programs/neovim.nix`: Neovim text editor
   - `programs/zsh.nix`: Zsh shell configuration

2. **Desktop Environment**:

   - `desktop/gnome/`: Gnome configuration
   - `desktop/hyprland/`: Hyprland window manager setup
   - `services/waybar/`: Custom status bar configuration
   - `services/swaync/`: Notification center setup

3. **Development**:

   - `programs/go.nix`: Go development environment
   - `programs/rust.nix`: Rust development environment
   - `programs/krew.nix`: Kubernetes plugin manager
   - `scripts/`: Collection of development utilities

4. **macOS Specific**:
   - `programs/aerospace.nix`: macOS window management

Example repos:

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

Literature to read:

<https://callistaenterprise.se/blogg/teknik/2025/04/10/nix-flakes/>
