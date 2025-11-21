# Reis-New - CachyOS Setup Notes

Host-specific setup instructions and discoveries for the reis-new machine running CachyOS.

## Quick Setup

For automated setup, use the provided scripts:

### Bootstrap Script

Run the main setup script to install and configure most packages automatically:

```bash
./scripts/setup.sh
```

This script will:
- Install yay and gaming packages
- Configure shell (zsh)
- Install and configure CoolerControl with fan control kernel parameters
- Install audio tools (EasyEffects, LSP plugins, Calf) and restore presets
- Install printing support (CUPS)
- Install and configure OpenRGB with saved profiles
- Setup gaming drive mount
- Install CUDA
- Verify backup tools (Snapper, BTRFS-Assistant)

### Temperature Sensors DKMS Module

After running the bootstrap script (or after each major CachyOS update), install/update the temperature sensors module:

```bash
./scripts/asus-ec-sensors.sh
```

This script will:
- Clone the asus-ec-sensors repository if not present
- Build and install the DKMS module
- Run sensors auto-detection

## Manual Setup Details

The sections below document the manual steps for reference. Most of these are automated by the scripts above.

## Initial Setup

### Gaming Packages

Install the gaming packages:

```bash
sudo pacman -S cachyos-gaming-meta cachyos-gaming-applications
```

### Shell Configuration

Switching to zsh using the Nix profile directory on CachyOs broke all Dolphin applications and mime links. Instead:

```bash
chsh -s /usr/bin/zsh
```

### System Services

Trying to manage systemd services on home manager sucks. CoolerControl required a service so instead I installed it through [yay on CachyOs](https://docs.coolercontrol.org/installation/arch.html).

## Hardware Configuration

### Fan Control

To get fan control working on CoolerControl add the following to the end of `/etc/default/limine`:

```text
acpi_enforce_resources=lax
```

Then run:

```bash
sudo limine-update
```

### Temperature Sensors

To get T_Sensor values, I forked the [asus-ec-sensors](https://github.com/zeule/asus-ec-sensors) repository [here](https://github.com/reisholmes/asus-ec-sensors). It probably won't ever be pushed through to mainline as my motherboard is old and has two EC chips in it, making it difficult to find the correct sensors to poll, see the [PR here](https://github.com/zeule/asus-ec-sensors/pull/64) for more information.

To install the module, go to the directory containing the repo and run:

```bash
sudo pacman -S yay
yay dkms
# Select: 2 cachyos/dkms 3.2.1-2 (46.7 KiB 151.2 KiB)

sudo CC=gcc make modules
sudo CC=gcc make modules_install
sudo CC=gcc make dkms_configure
sudo CC=gcc make dkms
```

## Applications

### Password Management

Proton Pass has replaced 1password. Password managers can have issues installing
through home-manager alone. On my desktops I use the inbuilt package manager,
e.g. `yay proton-pass-bin` on Mac I use Homebrew.

### Audio Setup

Sound control (for EQ) is setup via [EasyEffects](https://github.com/wwmm/easyeffects):

```bash
yay easyeffects
yay lsp-plugins-lv2
```

When prompted for lv2-host provider, select option 1 (ardour from cachyos-extra-v3).

#### Microphone Control

Microphone control, boosting and ensuring it's being presented Stereo to Mono, is performed with the `Stereo Tools` plugin from Calf:

```bash
yay calf-no-gui
# Select: aur/calf-no-gui
```

Test with:

```bash
yay audacity
```

### Printing

Install printing support:

```bash
sudo pacman -S hplip python-pyqt5 python-reportlab cups cups-filters cups-pdf print-manager
```

Note: hplip may not be necessary for all printers.

Access the cups server: `http://localhost:631/`

Get a GUI with:

```bash
yay system-config-printer
```

### RGB Control

Setup through OpenRGB:

```bash
yay openrgb
# Select from cachyos-extra-v3
```

## Gaming Configuration

### Mount Gaming Drive

```bash
sudo mkdir /mnt/games
echo "UUID=8E3E36AB3E368C69 /mnt/games ntfs-3g   uid=1000,gid=1000    0       0" | sudo tee -a /etc/fstab
yay ntfs-3g
sudo mount -a
```

### Steam Setup

Follow the instructions at the [CachyOS wiki](https://wiki.cachyos.org/configuration/gaming/).

### Proton Drivers

Install additional proton drivers for newer games:

- <https://github.com/augustobmoura/asdf-protonge?tab=readme-ov-file>
- <https://github.com/GloriousEggroll/proton-ge-custom?tab=readme-ov-file#installation>

### Sunshine (Game Streaming)

Install CUDA before Sunshine:

```bash
yay cuda
```

Ensure you get Sunshine from the built packages or build yourself. Don't install through `yay sunshine` as it did not properly detect CUDA. See [Sunshine documentation](https://docs.lizardbyte.dev/projects/sunshine/latest/md_docs_2getting__started.html).

## Backup & Restore

### System Snapshots

System backups are performed using Snapper with BTRFS-Assistant providing a GUI interface.

#### Quick Restore Reference

**Using BTRFS-Assistant (GUI)**:
1. Open BTRFS-Assistant
2. Navigate to the Snapper tab
3. Select the snapshot to restore
4. Click "Restore" and choose restore method (in-place or create new snapshot)

**Using Snapper (CLI)**:
```bash
# List snapshots
snapper list

# View differences between current system and snapshot
snapper status <snapshot-number>

# Restore from snapshot (creates new snapshot of current state first)
snapper undochange <snapshot-number-from>..<snapshot-number-to>

# Or restore entire snapshot
snapper rollback <snapshot-number>
```

**Boot from Snapshot** (for critical failures):
1. Reboot system
2. At GRUB menu, select "CachyOS snapshots"
3. Choose desired snapshot to boot from
4. Once booted, make snapshot permanent: `snapper rollback`
