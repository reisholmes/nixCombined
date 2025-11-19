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

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

ASUS EC Sensors DKMS Module Update Script

This script manages the custom ASUS EC Sensors kernel module for ASUS motherboards.
It clones/updates the repository, builds, and installs the DKMS module.

The module is required to expose temperature sensors (T_Sensor values) on older
ASUS motherboards that are not supported by mainline kernel drivers.

Repository: https://github.com/reisholmes/asus-ec-sensors (feat/maximus_x_hero branch)

OPTIONS:
    -h, --help     Show this help message and exit

ENVIRONMENT VARIABLES:
    REPOS_DIR      Directory for cloning the repository (default: \$HOME/Documents/repos)

NOTES:
  - Requires DKMS to be installed (will be installed automatically if missing)
  - Must be run after each major kernel update
  - Requires sudo access for kernel module installation
  - A reboot may be required for changes to take effect

EXAMPLES:
  $(basename "$0")                      Run with default settings
  REPOS_DIR=~/src $(basename "$0")      Use custom repository directory
  $(basename "$0") --help               Show this help message

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

REPOS_DIR="${REPOS_DIR:-$HOME/Documents/repos}"
ASUS_EC_SENSORS_REPO="$REPOS_DIR/asus-ec-sensors"

echo_info "ASUS EC Sensors DKMS Module Update Script"
echo_info "=========================================="
echo ""

# Check if repos directory exists
if [ ! -d "$REPOS_DIR" ]; then
    echo_warn "Repos directory not found. Creating: $REPOS_DIR"
    if ! mkdir -p "$REPOS_DIR"; then
        echo_error "Failed to create repos directory: $REPOS_DIR"
        exit 1
    fi
fi

# Check if the repo exists
if [ ! -d "$ASUS_EC_SENSORS_REPO" ]; then
    echo_error "ASUS EC Sensors repository not found at: $ASUS_EC_SENSORS_REPO"
    echo_info "Cloning repository from feature branch..."
    cd "$REPOS_DIR" || {
        echo_error "Failed to change to repos directory"
        exit 1
    }
    if ! git clone -b feat/maximus_x_hero https://github.com/reisholmes/asus-ec-sensors.git; then
        echo_error "Failed to clone repository"
        exit 1
    fi
    echo_info "Repository cloned successfully"
fi

echo_info "Repository found at: $ASUS_EC_SENSORS_REPO"
echo_info "Changing to repository directory..."
cd "$ASUS_EC_SENSORS_REPO" || {
    echo_error "Failed to change to repository directory"
    exit 1
}

# Check if dkms is installed
if ! command -v dkms &> /dev/null; then
    echo_warn "DKMS not found. Installing..."
    if ! yay -S --needed --noconfirm dkms; then
        echo_error "Failed to install DKMS"
        exit 1
    fi
fi

echo_info "Cleaning previous build artifacts..."
if ! sudo LLVM=true make clean; then
    echo_error "Failed to clean build artifacts"
    exit 1
fi

echo_info "Building modules..."
if ! sudo LLVM=true make modules; then
    echo_error "Failed to build modules"
    exit 1
fi

echo_info "Installing modules..."
if ! sudo LLVM=true make modules_install; then
    echo_error "Failed to install modules"
    exit 1
fi

echo_info "Configuring DKMS..."
if ! sudo LLVM=true make dkms_configure; then
    echo_error "Failed to configure DKMS"
    exit 1
fi

echo_info "Installing DKMS module..."
if ! sudo LLVM=true make dkms; then
    echo_error "Failed to install DKMS module"
    exit 1
fi

echo_info "Running sensors auto-detection..."
if ! sudo sensors-detect --auto; then
    echo_warn "Sensors auto-detection failed or was cancelled"
fi

echo ""
echo_info "=== DKMS Module Update Complete ==="
echo ""
echo_warn "A reboot may be required for changes to take effect"
echo_info "After reboot, verify sensors with: sensors"
