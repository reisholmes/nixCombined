# rh-sb3 Configuration

Personal Linux machine configuration.

## System Information

- **User**: reis
- **Configuration**: home-manager (standalone)

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
