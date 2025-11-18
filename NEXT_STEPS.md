# Migration Progress Tracker

**Branch**: `merge-nix-darwin`
**Status**: Analysis Complete - Ready for Implementation
**Last Updated**: 2025-11-18

---

## What's Been Completed

- ✅ Created `merge-nix-darwin` branch
- ✅ Analyzed both nixCombined and nix-darwin repositories
- ✅ Identified all gaps and duplications
- ✅ Documented complete migration strategy in `MIGRATION_ANALYSIS.md`
- ✅ Confirmed zero-downtime migration is possible

---

## What's Next

### Phase 1: Fill Package Gaps (Required before migration)

1. **Add missing Homebrew packages**
   - Edit: `home/reis.holmes/reis-work/homebrew.nix`
   - Add to `brews`: `"node"`, `"podman"`
   - Add to `casks`: `"proton-pass"`

2. **Add missing Nix packages**
   - Edit: `modules/home-manager/dev/default.nix`
   - Add to Darwin packages: `gh`, `lsd`, `claude-code`

3. **Verify k9s configuration**
   - Check: `modules/home-manager/programs/k9s/default.nix`
   - Compare with: `../nix-darwin/home/modules/k9s/`
   - Ensure skins and views are present

4. **Check ZSH configuration**
   - Review: `modules/home-manager/programs/zsh/default.nix`
   - Verify these aliases exist:
     - `cat` → `bat`
     - `ls` → `eza`
     - `lt` → `lsd --tree`
   - Add if missing: `nix_rebuild` alias

### Phase 2: Test Before Migration

```bash
# Switch to the branch
cd /Users/reis.holmes/Documents/code/personal_repos/nixCombined
git checkout merge-nix-darwin

# Build without switching (dry run)
darwin-rebuild build --flake .#reis-work

# Review what will change
nix store diff-closures /run/current-system ./result

# If satisfied, commit changes
git add .
git commit -m "Add missing packages from nix-darwin"
```

### Phase 3: Perform Migration

```bash
# Switch to the new configuration
darwin-rebuild switch --flake .#reis-work

# Test key applications
- Open Kitty terminal
- Run `gh --version`
- Check k9s works: `k9s`
- Verify node: `node --version`
- Test podman: `podman --version`

# If issues occur, rollback instantly:
darwin-rebuild switch --rollback
```

### Phase 4: Cleanup (After successful migration)

```bash
# Update shell startup to use nixCombined
# Edit ~/.zshrc if it references nix-darwin path

# Archive nix-darwin repo
cd /Users/reis.holmes/Documents/code/personal_repos/nix-darwin
git tag archived-$(date +%Y%m%d)
git push --tags

# Merge the branch in nixCombined
cd /Users/reis.holmes/Documents/code/personal_repos/nixCombined
git checkout master
git merge merge-nix-darwin
git push
```

---

## Optional Improvements (Post-Migration)

### High Priority
- [ ] Create dedicated program modules for: `gh`, `bat`, `neovim`
- [ ] Add documentation in `docs/` directory:
  - `MACHINE_SETUP.md`
  - `ADDING_PROGRAMS.md`
  - `TROUBLESHOOTING.md`
  - `ARCHITECTURE.md`

### Medium Priority
- [ ] Reorganize into more granular layers:
  - `modules/home-manager/cloud/` - AWS, Azure, GCloud
  - `modules/home-manager/kubernetes/` - kubectl, k9s, flux
  - `modules/home-manager/infra/` - Terraform, Terragrunt, etc.
- [ ] Add CI/CD checks (`.github/workflows/check.yml`)
- [ ] Standardize Nix vs Homebrew with documented decision matrix

### Low Priority
- [ ] Review and optimize package sources
- [ ] Add more comprehensive testing
- [ ] Create migration log documenting lessons learned

---

## Quick Reference Commands

```bash
# Current working directory
cd /Users/reis.holmes/Documents/code/personal_repos/nixCombined

# Build configuration (no changes)
darwin-rebuild build --flake .#reis-work

# Apply configuration
darwin-rebuild switch --flake .#reis-work

# Rollback to previous generation
darwin-rebuild switch --rollback

# List generations
darwin-rebuild --list-generations

# Compare system closures
nix store diff-closures /run/current-system ./result

# Update flake inputs
nix flake update

# Check flake validity
nix flake check
```

---

## Files to Edit

### Required Changes

1. **`home/reis.holmes/reis-work/homebrew.nix`**
   - Lines to modify: `brews` array (add node, podman)
   - Lines to modify: `casks` array (add proton-pass)

2. **`modules/home-manager/dev/default.nix`**
   - Lines to modify: Darwin packages section (~line 46)
   - Add: `gh`, `lsd`, `claude-code`

### Files to Verify

1. **`modules/home-manager/programs/k9s/default.nix`**
   - Ensure complete configuration exists
   - Compare with `../nix-darwin/home/modules/k9s/`

2. **`modules/home-manager/programs/zsh/default.nix`**
   - Verify aliases present
   - Check plugin configuration

---

## Risk Assessment

**Overall Risk**: LOW

- Same state versions prevent incompatibilities
- Nix store shared between configurations
- Instant rollback available
- No data loss risk
- User home directory untouched

**Estimated Time**: 30-60 minutes for migration, 1-2 hours for gap filling

---

## Key Insights from Analysis

1. **nixCombined already has ~80% of nix-darwin config**
2. **No reinstall needed** - just symlink updates
3. **Both use same nix-darwin foundation** - safe to switch
4. **Modular architecture is superior** - worth the migration
5. **Rollback is instant** - low risk operation

---

## Questions & Answers

**Q: Will I need to reinstall apps?**
A: No! Packages in `/nix/store` are reused. Only missing packages get added.

**Q: What if something breaks?**
A: Run `darwin-rebuild switch --rollback` - takes ~5 seconds.

**Q: Will my data be affected?**
A: No. User data and home directory are untouched by config changes.

**Q: How long will this take?**
A: Building: 5-10 min. Switching: 1-2 min. Testing: 10-20 min.

---

## Reference Documents

- **Full Analysis**: `MIGRATION_ANALYSIS.md` - Complete detailed analysis
- **nix-darwin location**: `/Users/reis.holmes/Documents/code/personal_repos/nix-darwin`
- **nixCombined location**: `/Users/reis.holmes/Documents/code/personal_repos/nixCombined`

---

## Session Context for Future Reference

This migration consolidates two Nix configurations:
1. **nix-darwin** - Original single-machine setup for work Mac
2. **nixCombined** - Multi-machine setup for work Mac + 2 Linux machines

Goal: Unified repository with modular architecture that scales across all machines.

The work was performed in a single analysis session where both repos were thoroughly examined, compared, and a migration strategy developed. The key finding was that nixCombined already contains most of the nix-darwin functionality, so this is more of a "gap filling" exercise than a full merge.
