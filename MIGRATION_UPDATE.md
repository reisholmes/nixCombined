# Migration Update - nix-darwin Recent Changes

**Date**: 2025-11-18
**Branch**: `merge-nix-darwin`

## Recent nix-darwin Modifications

Since the initial migration analysis, the nix-darwin repository has received several important updates:

### Key Changes (Last 5 commits)

1. **7cc6150** - Switched from Kitty to Ghostty terminal
2. **5888a54** - Remove fish comment line
3. **2bfe89a** - Update zsh to disable zoxide if in Claude Code
4. **6b71987** - Add homebrew packages, update nix config, and enhance shell setup
5. **eda9a4a** - Add pre-commit requirements, updated zsh plugin

---

## Comparison Analysis

### 1. Ghostty Terminal Configuration

**Status**: ✅ Already in sync

Both repositories have:
- Identical ghostty config files
- Catppuccin Mocha theme
- Same window size (160x44)
- Same opacity (0.85) and blur (32)
- Same keybindings

**Difference**:
- nix-darwin: Installs ghostty via Homebrew cask
- nixCombined: Installs ghostty via Nix package (in common module)

**Action**: ⚠️ Add ghostty to Homebrew casks for consistency with nix-darwin approach (macOS GUI apps often work better via Homebrew)

### 2. Missing Packages

#### From Homebrew (nix-darwin → nixCombined)

Missing **brews**:
- `node` - Node.js runtime

Missing **casks**:
- `proton-pass` - Password manager
- `ghostty` - Terminal emulator (using Nix package instead)

#### From Nix Packages (nix-darwin → nixCombined)

Missing from common/dev modules:
- `gh` - GitHub CLI
- `lsd` - Modern ls with tree view
- `claude-code` - Claude Code CLI

### 3. ZSH Configuration Updates

**New in nix-darwin** (lines 35-38 in home/modules/zsh.nix):
```bash
# Disable zoxide cd override for Claude Code sessions
if [[ -n "$CLAUDE_CODE_SESSION" ]]; then
  alias cd='builtin cd'
fi
```

**Status**: ⚠️ Missing in nixCombined

**Importance**: High - This prevents the zoxide cd command error we're seeing in the current session!

**Missing alias**:
- `lt = "lsd --tree"` - Tree view using lsd

---

## Required Changes

### 1. Update homebrew.nix

**File**: `home/reis.holmes/reis-work/homebrew.nix`

Add to `brews` array:
```nix
"node"
```

Add to `casks` array:
```nix
"ghostty"  # Switch from Nix package to Homebrew for consistency
"proton-pass"
```

### 2. Update common module

**File**: `modules/home-manager/common/default.nix`

Add to `home.packages`:
```nix
gh         # GitHub CLI
lsd        # Modern ls with tree view
claude-code # Claude Code CLI
```

**Note**: Remove `deskflow` from common packages as it's already in Homebrew

### 3. Update ZSH configuration

**File**: `modules/home-manager/programs/zsh/default.nix`

Add to `initContent` (after fastfetch):
```nix
# Disable zoxide cd override for Claude Code sessions
if [[ -n "$CLAUDE_CODE_SESSION" ]]; then
  alias cd='builtin cd'
fi
```

Add to `shellAliases`:
```nix
# list tree
lt = "lsd --tree";
```

---

## Updated Migration Checklist

### Pre-Migration (Required)

- [ ] Add `node` to homebrew brews
- [ ] Add `proton-pass` and `ghostty` to homebrew casks
- [ ] Add `gh`, `lsd`, `claude-code` to common packages
- [ ] Add Claude Code session detection to ZSH
- [ ] Add `lt` alias to ZSH

### Build & Test

- [ ] Build configuration: `darwin-rebuild build --flake .#reis-work`
- [ ] Review changes: `nix store diff-closures /run/current-system ./result`
- [ ] Commit changes to merge branch

### Migration

- [ ] Switch configuration: `darwin-rebuild switch --flake .#reis-work`
- [ ] Test critical tools:
  - [ ] `gh --version`
  - [ ] `node --version`
  - [ ] `lsd --version`
  - [ ] `claude-code --version`
  - [ ] Open Ghostty terminal
  - [ ] Test `lt` alias
  - [ ] Verify cd works in Claude Code (no zoxide error)

### Post-Migration

- [ ] Update shell startup files to use nixCombined path
- [ ] Archive nix-darwin repository
- [ ] Merge branch to main
- [ ] Document lessons learned

---

## Key Insights

### 1. Ghostty vs Kitty

nix-darwin has **migrated from Kitty to Ghostty**. nixCombined already has ghostty configured but installs it via Nix. For better macOS integration, switching to Homebrew cask is recommended.

### 2. Claude Code ZSH Fix

The zoxide cd command error we're experiencing is due to **missing Claude Code session detection** in nixCombined's ZSH config. This fix is critical and should be applied immediately.

### 3. Package Installation Methods

**Observation**: nix-darwin uses Homebrew for `ghostty` while nixCombined uses Nix package.

**Recommendation**: For macOS GUI apps, prefer Homebrew casks for better system integration, especially for newer apps like Ghostty.

### 4. Missing Development Tools

Three important CLI tools are missing from nixCombined:
- `gh` (GitHub CLI) - Critical for GitHub operations
- `lsd` (modern ls) - Used by `lt` alias for tree views
- `claude-code` - Already in nix-darwin, should be in nixCombined

---

## Risk Assessment

**Overall Risk**: LOW

**New Risks Identified**:
1. Ghostty installation method difference
   - Impact: Low
   - Mitigation: Add to Homebrew casks
2. Missing ZSH Claude Code detection
   - Impact: Medium (causes current cd errors)
   - Mitigation: Add detection to ZSH config
3. Missing `lsd` package
   - Impact: Low (`lt` alias won't work)
   - Mitigation: Add to common packages

---

## Benefits of These Updates

1. **Fixes current issues**: Resolves zoxide cd command error in Claude Code
2. **Feature parity**: Ensures nixCombined has all nix-darwin functionality
3. **Better UX**: `lt` alias provides convenient tree view
4. **GitHub integration**: `gh` CLI enables GitHub operations
5. **Consistency**: All tools available across both configurations

---

## Next Steps

1. Apply all required changes to nixCombined
2. Build and test the updated configuration
3. Perform the migration
4. Verify all functionality works as expected
5. Document any issues encountered during migration

---

## References

- **nix-darwin commits**: Last 5 commits reviewed (7cc6150 to 13257dd)
- **Main differences**: Ghostty terminal, ZSH Claude Code fix, missing packages
- **Migration strategy**: Original analysis in `MIGRATION_ANALYSIS.md` still valid
- **Risk level**: Still LOW with instant rollback capability
