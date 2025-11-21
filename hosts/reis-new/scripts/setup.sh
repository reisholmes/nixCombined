#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Automated setup script for reis-new CachyOS host.

This script installs and configures:
  - Gaming packages (cachyos-gaming-meta, cachyos-gaming-applications)
  - Shell (zsh)
  - CoolerControl with fan control kernel parameters
  - Audio tools (EasyEffects, LSP plugins, Calf) with preset restoration
  - Printing support (CUPS, system-config-printer)
  - OpenRGB with profile restoration
  - Gaming drive mount (/mnt/games)
  - CUDA for game streaming
  - Backup tools (Snapper, BTRFS-Assistant)

OPTIONS:
    -h, --help     Show this help message and exit

NOTES:
  - This script is designed for CachyOS but may work on other Arch-based distributions
  - Requires sudo access for system-level changes
  - A reboot is recommended after completion
  - Configuration files are restored from modules/home-manager/assets/

EXAMPLES:
  $(basename "$0")              Run the full setup
  $(basename "$0") --help       Show this help message

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        *)
            echo_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ASSETS_DIR="$REPO_ROOT/modules/home-manager/assets"

# Check if running on CachyOS
if ! grep -q "CachyOS" /etc/os-release 2>/dev/null; then
    echo_warn "This script is designed for CachyOS. Proceed with caution."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo_info "Starting reis-new CachyOS setup..."
echo_info "Repository root: $REPO_ROOT"

# Install yay if not present
echo_step "Checking for yay..."
if ! command -v yay &> /dev/null; then
    echo_info "yay not found. Installing..."
    if ! sudo pacman -S --needed --noconfirm yay; then
        echo_error "Failed to install yay. Manual intervention is required. Command attempted: sudo pacman -S --needed --noconfirm yay"
        exit 1
    fi
    echo_info "yay installed successfully"
else
    echo_info "yay already installed"
fi

# Install gaming packages
echo_step "Installing gaming packages..."
sudo pacman -S --needed --noconfirm cachyos-gaming-meta cachyos-gaming-applications

# Configure shell
echo_step "Configuring shell..."
current_shell=$(getent passwd $USER | cut -d: -f7)
if [[ "$current_shell" != "/usr/bin/zsh" ]]; then
    echo_info "Changing shell to zsh..."
    chsh -s /usr/bin/zsh
    echo_info "Shell changed to zsh. You'll need to log out and back in for this to take effect."
else
    echo_info "Shell already set to zsh"
fi

# Install CoolerControl
echo_step "Installing CoolerControl..."
yay -S --needed --noconfirm coolercontrol

# Restore CoolerControl configuration if available
if [ -f "$ASSETS_DIR/coolercontrol/coolercontrol-backup.tgz" ]; then
    echo_info "Restoring CoolerControl configuration..."
    if [ ! -d ~/.config/org.coolercontrol.CoolerControl ]; then
        mkdir -p ~/.config/org.coolercontrol.CoolerControl || {
            echo_error "Failed to create CoolerControl config directory"
            exit 1
        }
    fi
    if tar -xzf "$ASSETS_DIR/coolercontrol/coolercontrol-backup.tgz" -C ~/.config/org.coolercontrol.CoolerControl; then
        echo_info "CoolerControl configuration restored to ~/.config/org.coolercontrol.CoolerControl/"
    else
        echo_error "Failed to restore CoolerControl configuration"
        exit 1
    fi
else
    echo_warn "CoolerControl backup not found, skipping restore"
fi

# Configure fan control kernel parameter
echo_step "Configuring fan control kernel parameter..."
if ! grep -q "acpi_enforce_resources=lax" /etc/default/limine 2>/dev/null; then
    echo "acpi_enforce_resources=lax" | sudo tee -a /etc/default/limine
    echo_info "Running limine-update..."
    sudo limine-update
    echo_warn "Reboot required for fan control to work"
else
    echo_info "Fan control kernel parameter already configured"
fi

# Install password manager
echo_step "Installing Proton Pass..."
yay -S --needed --noconfirm proton-pass-bin

# Install audio tools
echo_step "Installing audio tools (EasyEffects, LSP plugins, Calf)..."
yay -S --needed --noconfirm easyeffects

# Install lsp-plugins-lv2 with automatic provider selection
echo_info "Installing LSP plugins (selecting ardour as lv2-host provider)..."
yay -S --needed --noconfirm lsp-plugins-lv2 --answerclean None --answerdiff None --answerprovider ardour 2>/dev/null || {
    echo_warn "Automatic provider selection failed, you may need to select ardour manually"
    yay -S --needed --noconfirm lsp-plugins-lv2
}

# Install Calf for microphone control
echo_info "Installing Calf (no-gui version)..."
yay -S --needed --noconfirm calf --answerclean None --answerdiff None

# Restore EasyEffects presets
if [ -d "$ASSETS_DIR/easyeffects/outputs" ]; then
    echo_info "Restoring EasyEffects presets..."
    if [ ! -d ~/.local/share/easyeffects/output ]; then
        mkdir -p ~/.local/share/easyeffects/output || {
            echo_error "Failed to create EasyEffects preset directory"
            exit 1
        }
    fi
    if cp -v "$ASSETS_DIR/easyeffects/outputs/"*.json ~/.local/share/easyeffects/output/; then
        echo_info "EasyEffects presets restored to ~/.local/share/easyeffects/output/"
    else
        echo_error "Failed to restore EasyEffects presets"
        exit 1
    fi
else
    echo_warn "EasyEffects presets not found, skipping restore"
fi

# Install printing support
echo_step "Installing printing support..."
sudo pacman -S --needed --noconfirm hplip python-pyqt5 python-reportlab cups cups-filters cups-pdf print-manager

echo_info "Enabling CUPS service..."
sudo systemctl enable --now cups.service

# Install system-config-printer GUI
yay -S --needed --noconfirm system-config-printer

# Install RGB control
echo_step "Installing OpenRGB..."
yay -S --needed --noconfirm openrgb --answerclean None --answerdiff None

# Restore OpenRGB profile
if [ -f "$ASSETS_DIR/openrgb/reis_default.orp" ]; then
    echo_info "Restoring OpenRGB profile..."
    if [ ! -d ~/.config/OpenRGB ]; then
        mkdir -p ~/.config/OpenRGB || {
            echo_error "Failed to create OpenRGB config directory"
            exit 1
        }
    fi
    if cp -v "$ASSETS_DIR/openrgb/reis_default.orp" ~/.config/OpenRGB/; then
        echo_info "OpenRGB profile restored to ~/.config/OpenRGB/reis_default.orp"
    else
        echo_error "Failed to restore OpenRGB profile"
        exit 1
    fi
else
    echo_warn "OpenRGB profile not found, skipping restore"
fi

# Setup gaming drive mount
echo_step "Setting up gaming drive mount..."
if ! grep -q "8E3E36AB3E368C69" /etc/fstab 2>/dev/null; then
    if [ ! -d "/mnt/games" ]; then
        sudo mkdir -p /mnt/games
    fi

    yay -S --needed --noconfirm ntfs-3g

    echo "UUID=8E3E36AB3E368C69 /mnt/games ntfs-3g   uid=$(id -u),gid=$(id -g)    0       0" | sudo tee -a /etc/fstab

    echo_info "Mounting gaming drive..."
    sudo mount -a

    if mountpoint -q /mnt/games; then
        echo_info "Gaming drive mounted successfully"
    else
        echo_error "Failed to mount gaming drive. Check UUID and /etc/fstab"
    fi
else
    echo_info "Gaming drive already configured in fstab"
fi

# Install CUDA for Sunshine
echo_step "Installing CUDA..."
yay -S --needed --noconfirm cuda

echo_info "To install Sunshine with CUDA support:"
echo_info "  1. Download sunshine.pkg.tar.zst from: https://github.com/LizardByte/Sunshine/releases"
echo_info "  2. Install with: sudo pacman -U --noconfirm sunshine.pkg.tar.zst"
echo_warn "Do NOT install Sunshine via yay as it may not detect CUDA properly"

# Check for backup tools (likely pre-installed on CachyOS)
echo_step "Checking backup tools..."
if command -v snapper &> /dev/null && command -v btrfs-assistant &> /dev/null; then
    echo_info "Snapper and BTRFS-Assistant already installed (likely by default)"
else
    echo_info "Installing Snapper and BTRFS-Assistant..."
    yay -S --needed --noconfirm snapper btrfs-assistant
fi

echo ""
echo_info "=== Setup Complete ==="
echo ""
echo_info "Configuration files restored:"
echo_info "  - CoolerControl: ~/.config/org.coolercontrol.CoolerControl/"
echo_info "  - EasyEffects: ~/.local/share/easyeffects/output/"
echo_info "  - OpenRGB: ~/.config/OpenRGB/reis_default.orp"
echo ""
echo_info "Manual steps remaining:"
echo_info "  1. Install Temperature Sensors DKMS module:"
echo_info "     Run: $SCRIPT_DIR/update-asus-ec-sensors.sh"
echo_info "     (Required after each major CachyOS update)"
echo ""
echo_info "  2. Install Proton-GE custom drivers for Steam:"
echo_info "     https://github.com/augustobmoura/asdf-protonge"
echo_info "     https://github.com/GloriousEggroll/proton-ge-custom#installation"
echo ""
echo_info "  3. Install Sunshine from built packages with CUDA support:"
echo_info "     https://github.com/LizardByte/Sunshine/releases"
echo_info "     Download sunshine.pkg.tar.zst and run:"
echo_info "     sudo pacman -U --noconfirm sunshine.pkg.tar.zst"
echo ""
echo_info "  4. Configure Steam following CachyOS wiki:"
echo_info "     https://wiki.cachyos.org/configuration/gaming/"
echo ""
echo_info "Useful resources:"
echo_info "  - CUPS web interface: http://localhost:631/"
echo_info "  - Test microphone input and effects with: yay audacity"
echo ""
echo_warn "A reboot is recommended to apply kernel parameters and other system changes"
