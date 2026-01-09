# rh-sb3 (Linux)

Personal Microsoft Surface Book 2 - Linux development machine.

## Machine Info

- **Hostname**: rh-sb3
- **Platform**: Linux Mint (standalone home-manager)
- **User**: reis
- **Architecture**: x86_64-linux
- **Hardware**: Microsoft Surface Book 2
- **Graphics**: Intel iGPU (tablet) + NVIDIA dGPU (keyboard base, Optimus)

## Hardware Configuration

### Microsoft Surface Book 2

This is a Surface Book 2 with detachable screen and hybrid graphics.

**Key Features**:
- Detachable screen (tablet/laptop modes)
- NVIDIA GPU in keyboard base (performance mode)
- Intel GPU in tablet portion (battery efficiency)
- Hybrid graphics via NVIDIA Optimus

**Graphics Setup**:
- **Intel iGPU**: Always available, used in tablet mode and for power efficiency
- **NVIDIA dGPU**: Only available when keyboard base is attached, used for performance
- **NixGL Configuration**: Uses `nvidiaPrime` profile for hybrid graphics

### NixGL Configuration

Since this is a non-NixOS Linux system, NixGL is used for proper graphics acceleration:

```nix
nixgl = {
  enable = true;
  profile = "nvidiaPrime";  # Hybrid Intel + NVIDIA
};
```

**How it works**:
- GUI applications are automatically wrapped with NixGL
- Intel GPU is used by default (mesa)
- NVIDIA GPU available via prime offload when keyboard base attached
- No manual wrapper needed for most applications

**Testing Graphics**:
```bash
# Check which GPU is being used
glxinfo | grep "OpenGL renderer"

# List available GPUs
lspci | grep -E "VGA|3D"

# Force NVIDIA GPU for specific application (only works with keyboard base attached)
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia application-name
```

**Surface Book 2 Notes**:
- NVIDIA GPU only functional when keyboard base is attached
- Detaching screen switches to Intel GPU only
- Battery life significantly better in tablet mode (Intel GPU only)

## Setup

### Initial Bootstrap

```bash
# Install Nix (if not already installed)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Enable flakes
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf

# Restart nix-daemon
sudo systemctl restart nix-daemon

# Clone this repository
cd ~/Documents/code/personal_repos
git clone git@github.com:reisholmes/nixCombined.git
cd nixCombined

# Bootstrap home-manager
make bootstrap-home

# Or manually:
nix-shell -p home-manager
home-manager switch --flake .#reis@rh-sb3 --impure -b backup
```

### Rebuilding

```bash
# Using Makefile (recommended)
make home

# Or using alias (defined in home-manager config)
nix_rebuild

# Or manually:
home-manager switch --flake .#reis@rh-sb3 --impure -b backup
```

## System Notes

- **Display Manager**: Linux Mint default (not managed by home-manager)
- **Shell**: zsh (configured via home-manager)
- **Package Manager**: Home-manager for user packages, apt for system packages
- **Graphics**: NixGL handles OpenGL/Vulkan for nix-installed GUI applications

## Git Configuration

Git is managed through Nix with SSH commit signing enabled globally.

### What's Automated

- Git installation and base configuration
- Delta for enhanced diffs
- GitHub CLI credential helper
- SSH signing configuration
- Allowed signers file generation

### Manual Setup Required

#### SSH Keys

The following SSH keys must be manually maintained:

1. **GitHub Authentication**:
   - Used for git operations
   - Configured in SSH config

2. **Commit Signing Key**: `/home/reis/.ssh/private-signing-key-github`
   - **Private key**: `/home/reis/.ssh/private-signing-key-github`
   - **Public key**: `/home/reis/.ssh/private-signing-key-github.pub`
   - Used for signing all commits
   - Public key must be added to GitHub as a **Signing Key**

#### Initial Setup Steps

1. **Import Signing Key from Proton Pass**:
   ```bash
   # Copy private key from Proton Pass
   cat > ~/.ssh/private-signing-key-github
   # Paste private key, then Ctrl+D

   # Copy public key from Proton Pass
   cat > ~/.ssh/private-signing-key-github.pub
   # Paste public key, then Ctrl+D

   # Set correct permissions
   chmod 600 ~/.ssh/private-signing-key-github
   chmod 644 ~/.ssh/private-signing-key-github.pub
   ```

2. **Add Signing Key to GitHub**:
   ```bash
   # Display public key
   cat ~/.ssh/private-signing-key-github.pub
   ```
   - Go to GitHub Settings → SSH and GPG keys
   - Click "New SSH key"
   - Title: "rh-sb3 Commit Signing Key"
   - Key type: **Signing Key** (important!)
   - Paste the public key

3. **Verify SSH Config**:
   Ensure your `~/.ssh/config` has GitHub configured with your authentication key.

4. **Test Configuration**:
   ```bash
   # Test SSH connection
   ssh -T git@github.com

   # Test commit signing
   cd ~/Documents/code/personal_repos/*
   git commit --allow-empty -m "test: verify signing"
   git log --show-signature -1
   git reset --hard HEAD~1  # Remove test commit
   ```

### Configuration Details

- **Email**: `4367558+reisholmes@users.noreply.github.com` (GitHub private email)
- **Name**: `Reis Holmes` (from userConfig)
- **Commit Signing**: Enabled globally for all repositories
- **Signing Format**: SSH
- **Signing Key**: `/home/reis/.ssh/private-signing-key-github`

### Verification

Check your configuration:

```bash
# Show git config
git config --list --show-origin | grep -E "(user\.|gpg\.|commit\.)"

# Should show:
# user.name=Reis Holmes
# user.email=4367558+reisholmes@users.noreply.github.com
# commit.gpgsign=true
# gpg.format=ssh
```

### Troubleshooting

#### Signing Not Working

1. **Check signing key exists**:
   ```bash
   ls -la ~/.ssh/private-signing-key-github*
   ```

2. **Verify allowed_signers file**:
   ```bash
   cat ~/.ssh/allowed_signers
   # Should contain: 4367558+reisholmes@users.noreply.github.com ssh-ed25519 ...
   ```

3. **Test signing**:
   ```bash
   cd ~/Documents/code/personal_repos/*
   git commit --allow-empty -m "test"
   git log --show-signature -1
   ```

## Rebuilding Configuration

After making changes to your Nix configuration:

```bash
home-manager switch --flake .#reis@rh-sb3 --impure
```

Or use the alias:
```bash
nix_rebuild
```
