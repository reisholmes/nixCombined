#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

REPOS_DIR="$HOME/Documents/repos"
ASUS_EC_SENSORS_REPO="$REPOS_DIR/asus-ec-sensors"

echo_info "ASUS EC Sensors DKMS Module Update Script"
echo_info "=========================================="
echo ""

# Check if repos directory exists
if [ ! -d "$REPOS_DIR" ]; then
    echo_warn "Repos directory not found. Creating: $REPOS_DIR"
    mkdir -p "$REPOS_DIR"
fi

# Check if the repo exists
if [ ! -d "$ASUS_EC_SENSORS_REPO" ]; then
    echo_error "ASUS EC Sensors repository not found at: $ASUS_EC_SENSORS_REPO"
    echo_info "Cloning repository from feature branch..."
    cd "$REPOS_DIR"
    git clone -b feat/maximus_x_hero https://github.com/reisholmes/asus-ec-sensors.git
    echo_info "Repository cloned successfully"
fi

echo_info "Repository found at: $ASUS_EC_SENSORS_REPO"
echo_info "Changing to repository directory..."
cd "$ASUS_EC_SENSORS_REPO"

# Check if dkms is installed
if ! command -v dkms &> /dev/null; then
    echo_warn "DKMS not found. Installing..."
    yay -S --needed --noconfirm dkms
fi

echo_info "Cleaning previous build artifacts..."
sudo LLVM=true make clean

echo_info "Building modules..."
sudo LLVM=true make modules

echo_info "Installing modules..."
sudo LLVM=true make modules_install

echo_info "Configuring DKMS..."
sudo LLVM=true make dkms_configure

echo_info "Installing DKMS module..."
sudo LLVM=true make dkms

echo_info "Running sensors auto-detection..."
sudo sensors-detect --auto

echo ""
echo_info "=== DKMS Module Update Complete ==="
echo ""
echo_warn "A reboot may be required for changes to take effect"
echo_info "After reboot, verify sensors with: sensors"
