# reisholmes (macOS) Configuration

macOS machine for both work and personal development.

## System Information

- **OS**: macOS
- **User**: reis.holmes
- **Configuration**: nix-darwin + home-manager

## Git Configuration

Git is managed through Nix with conditional includes for work and personal repositories.

### What's Automated

- Git installation and base configuration
- Delta for enhanced diffs
- GitHub CLI credential helper
- Conditional configuration based on repository location
- SSH signing setup for personal repos
- Allowed signers file generation

### Manual Setup Required

#### SSH Keys

The following SSH keys must be manually maintained:

1. **Personal GitHub Authentication**: `~/.ssh/GitHub-Personal-SSHKey`
   - Used for git operations on personal repositories
   - Configured via SSH config with `github-personal` host

2. **Personal Commit Signing Key**: `~/.ssh/github_commit_signing_personal`
   - **Private key**: `~/.ssh/github_commit_signing_personal`
   - **Public key**: `~/.ssh/github_commit_signing_personal.pub`
   - Used for signing commits in personal repositories
   - Public key must be added to GitHub as a **Signing Key**

3. **Work GitHub Authentication** (if applicable): `~/.ssh/github-work`
   - Used for git operations on work repositories
   - Configured via SSH config with `github-work` host

#### Initial Setup Steps

1. **Generate or Import Signing Key**:
   ```bash
   # Option A: Generate new key
   ssh-keygen -t ed25519 -C "4367558+reisholmes@users.noreply.github.com" \
     -f ~/.ssh/github_commit_signing_personal -N ""

   # Option B: Import from Proton Pass
   # Copy private key → ~/.ssh/github_commit_signing_personal
   # Copy public key → ~/.ssh/github_commit_signing_personal.pub
   chmod 600 ~/.ssh/github_commit_signing_personal
   chmod 644 ~/.ssh/github_commit_signing_personal.pub
   ```

2. **Add Signing Key to GitHub**:
   ```bash
   # Display public key
   cat ~/.ssh/github_commit_signing_personal.pub
   ```
   - Go to GitHub Settings → SSH and GPG keys
   - Click "New SSH key"
   - Title: "macOS Commit Signing Key"
   - Key type: **Signing Key** (important!)
   - Paste the public key

3. **Verify SSH Config** (`~/.ssh/config`):
   ```
   # Personal GitHub
   Host github-personal
     HostName github.com
     User git
     IdentityFile ~/.ssh/GitHub-Personal-SSHKey
     IdentitiesOnly yes

   # Work GitHub
   Host github-work
     HostName github.com
     User git
     IdentityFile ~/.ssh/github-work
     IdentitiesOnly yes
   ```

4. **Test Configuration**:
   ```bash
   # Test SSH connections
   ssh -T git@github-personal
   ssh -T git@github-work

   # Test commit signing in personal repo
   cd ~/Documents/code/personal_repos/nixCombined
   git commit --allow-empty -m "test: verify signing"
   git log --show-signature -1
   git reset --hard HEAD~1  # Remove test commit
   ```

## How Git Configuration Works

### Directory-Based Configuration

Git uses conditional includes to apply different settings based on repository location:

#### Personal Repositories (`~/Documents/code/personal_repos/`)
- **Email**: `4367558+reisholmes@users.noreply.github.com` (GitHub private email)
- **Name**: `reisholmes`
- **Commit Signing**: Enabled (SSH)
- **Signing Key**: `~/.ssh/github_commit_signing_personal.pub`
- **SSH Host**: `github-personal` (uses personal SSH key)
- **URL Rewrite**: All GitHub URLs use `git@github-personal:`

#### Work Repositories (`~/Documents/code/repos/`)
- **Email**: Not set in Nix (configure manually if needed)
- **Name**: `Reis Holmes`
- **Commit Signing**: Disabled
- **SSH Host**: `github-work` (uses work SSH key)
- **URL Rewrite**: All GitHub URLs use `git@github-work:`
- **Work Email Setup** (if needed):
  ```bash
  cd ~/Documents/code/repos
  git config user.email "your-work-email@company.com"
  ```

### Verification

Check your current configuration:

```bash
# Show all git config with sources
git config --list --show-origin

# Check user info in a specific repo
cd ~/Documents/code/personal_repos/nixCombined
git config user.email  # Should show GitHub private email
git config user.name   # Should show: reisholmes

cd ~/Documents/code/repos/<some-work-repo>
git config user.email  # Your work email (if set)
git config user.name   # Should show: Reis Holmes
```

## Rebuilding Configuration

After making changes to your Nix configuration:

```bash
sudo darwin-rebuild switch --flake ~/Documents/code/personal_repos/nixCombined#reisholmes
```

Or use the alias:
```bash
nix_rebuild
```

## Troubleshooting

### Signing Not Working

1. **Check signing key exists**:
   ```bash
   ls -la ~/.ssh/github_commit_signing_personal*
   ```

2. **Verify allowed_signers file**:
   ```bash
   cat ~/.ssh/allowed_signers
   # Should contain: 4367558+reisholmes@users.noreply.github.com ssh-ed25519 ...
   ```

3. **Test signing manually**:
   ```bash
   cd ~/Documents/code/personal_repos/nixCombined
   git commit --allow-empty -m "test"
   git log --show-signature -1
   ```

### Wrong Email in Commits

Verify you're in the correct directory context:
```bash
pwd  # Check current directory
git config --get user.email  # Check what git will use
```

### SSH Connection Issues

Test SSH connections:
```bash
ssh -vT git@github-personal  # Should succeed
ssh -vT git@github-work      # Should succeed
```

If failing, check:
1. SSH keys exist and have correct permissions (600 for private, 644 for public)
2. `~/.ssh/config` has correct host configurations
3. Keys are added to respective GitHub accounts
