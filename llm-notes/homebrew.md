# Homebrew activation pitfalls

## Cleanup resets tap trust and aborts activation

- **Symptom**: with `homebrew.onActivation.cleanup = "uninstall"`, `darwin-rebuild switch` fails with `Refusing to load cask ... from untrusted tap`. `~/.homebrew/trust.json` is gone or empty afterward. Activation stops before home-manager runs.
- **Cause**: since Homebrew 7, `brew bundle --force-cleanup` resets `~/.homebrew/trust.json` to the trust that the Brewfile declares. A plain `tap "owner/repo"` line declares no trust. Cleanup removes trust granted with `brew trust`, and the next load of that tap fails. Homebrew documents this behavior at https://docs.brew.sh/Tap-Trust. Homebrew intends this behavior, so no Homebrew release will change it.
- **Fix**: in `darwin/programs/homebrew.nix`, give every non-official tap `trusted = true`:
  ```nix
  taps = [
    {
      name = "deskflow/homebrew-tap";
      trusted = true;
    }
  ];
  ```
  nix-darwin writes the entry as `tap "deskflow/homebrew-tap", trusted: true`. If you add a non-official tap without `trusted = true`, the next rebuild fails the same way.
- **Verify**: after `nix_rebuild`, `cat ~/.homebrew/trust.json` lists the tap under `trustedtaps`, and `brew tap` lists the tap.

## A removed formula hides the cask that replaced it

- **Symptom**: `az version` reports an old version, such as 2.90.0, while `brew info --cask azure-cli` reports a newer installed version. `brew upgrade` does not change the version.
- **Cause**: Homebrew deleted the `azure-cli` formula and replaced it with a cask. The old formula stays installed, and its `/opt/homebrew/bin/az` link blocks the cask's link. `brew upgrade` skips the formula because Homebrew has no formula definition left to upgrade to. When cleanup was `"none"`, activation never removed the formula either.
- **Fix**: `brew uninstall --formula azure-cli && brew reinstall --cask azure-cli && hash -r`. With `onActivation.cleanup = "uninstall"`, activation removes formulae that are not in `brews`. That stops this case from coming back on any machine. Activation does not relink the cask on a machine that is already broken, so run the fix above there.
- **Verify**: `readlink /opt/homebrew/bin/az` points into `/opt/homebrew/Caskroom/azure-cli/`, and `az version` matches the cask version.

## Related

- To preview what cleanup would remove, run `brew bundle cleanup --file=<Brewfile>` without `--force`. nix-darwin writes the active Brewfile to the Nix store. Find its path with `grep -o '/nix/store/[^ '\'']*-Brewfile' /run/current-system/activate | head -1`.
- To find the source of a package before you drop a tap, read the `tap` field in `brew info --json=v2 --installed`. A plain name like `lazydocker` can resolve to `homebrew/core` even if a third-party tap with the same name is tapped.
