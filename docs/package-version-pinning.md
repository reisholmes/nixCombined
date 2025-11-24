# Package Version Pinning in Nix

This guide explains how to install a specific version of a package when the desired version isn't available in your current nixpkgs channels (unstable or stable).

## The Problem

Sometimes you need a specific version of a package that isn't in your current nixpkgs:
- Latest version has breaking changes
- Need to match a specific environment
- Bug in newer version, need older stable version
- Specific feature only in certain version

**Example:** Both `nixpkgs-unstable` and `nixpkgs-stable` have `cowsay 3.8.4`, but you need `cowsay 3.8.3`.

## Solution: Pin Specific nixpkgs Revision

The best approach is to add a flake input pointing to a nixpkgs revision that contains your desired package version.

### Step 1: Find the nixpkgs Revision

Multiple tools are available for searching package versions across nixpkgs history:

#### Web-based Search Tools

**[Nix Package Versions](https://lazamar.co.uk/nix-versions/)** (lazamar)
- Simple, fast interface
- Shows package version history with commit hashes
- Great for quick lookups

**[Nix Package History](https://history.nix-packages.com/search)** (history.nix-packages.com)
- Comprehensive package version database
- Advanced filtering options
- Shows availability across channels

**[NixHub](https://www.nixhub.io)** (nixhub.io)
- Modern UI with detailed package information
- Version comparison features
- Links to source and documentation

#### Command-Line Tool

**[nix_version_search_cli](https://github.com/jeff-hykin/nix_version_search_cli)**

Run in isolated environment (no installation required):
```bash
# Run in temporary nix shell
nix shell https://github.com/jeff-hykin/nix_version_search_cli/archive/50a3fef5c9826d1e08b360b7255808e53165e9b2.tar.gz

# Search for package version
nix-version-search cowsay 3.8.3

# Output includes commit hash and date
```

**Note:** Check the [GitHub repo](https://github.com/jeff-hykin/nix_version_search_cli) for the latest tarball URL in the install instructions.

#### Manual Search (GitHub)

Search nixpkgs commit history directly:
```bash
# Clone nixpkgs (if you haven't already)
git clone https://github.com/NixOS/nixpkgs.git

# Search for version in commit history
cd nixpkgs
git log --all --oneline pkgs/tools/misc/cowsay/default.nix

# Check specific file at a commit
git show COMMIT_HASH:pkgs/tools/misc/cowsay/default.nix
```

**Using any tool above:**
1. Search for your package (e.g., "cowsay")
2. Find the row/entry with your desired version (e.g., "3.8.3")
3. Copy the commit hash (e.g., `abc123def456...`)

### Step 2: Add Flake Input

Add a new input to your `flake.nix` pointing to the specific revision:

```nix
{
  inputs = {
    # Existing inputs...
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # Pinned nixpkgs for specific package versions
    # Example: cowsay 3.8.3 (replace with actual commit hash)
    nixpkgs-cowsay-3-8-3 = {
      url = "github:nixos/nixpkgs/COMMIT_HASH_HERE";
      # Optional: reduce closure size by not following other inputs
      flake = false;
    };
  };
}
```

**Naming convention:** `nixpkgs-<package>-<version>` or `nixpkgs-<purpose>`

### Step 3: Make Available in Configuration

#### Option A: Via extraSpecialArgs (Recommended for Home Manager)

```nix
# In your mkHomeConfiguration function
mkHomeConfiguration = system: username: hostname:
  home-manager.lib.homeManagerConfiguration {
    pkgs = import nixpkgs {inherit system;};
    extraSpecialArgs = {
      inherit inputs outputs;
      # Add pinned packages
      pkgs-cowsay-3-8-3 = import inputs.nixpkgs-cowsay-3-8-3 {
        inherit system;
      };
    };
    modules = [ ./home/${username}/${hostname} ];
  };
```

#### Option B: Via specialArgs (For Darwin/NixOS)

```nix
# In your mkDarwinConfiguration or mkNixosConfiguration
mkDarwinConfiguration = hostname: username:
  nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit inputs outputs hostname;
      # Add pinned packages
      pkgs-cowsay-3-8-3 = import inputs.nixpkgs-cowsay-3-8-3 {
        system = "aarch64-darwin"; # or "x86_64-linux"
      };
    };
    modules = [ ./hosts/${hostname} ];
  };
```

### Step 4: Use in Configuration

In your home configuration or system configuration:

```nix
{
  pkgs,
  pkgs-cowsay-3-8-3,  # Pinned package set
  ...
}: {
  home.packages = [
    # Use regular packages from current nixpkgs
    pkgs.git
    pkgs.neovim

    # Use specific version from pinned nixpkgs
    pkgs-cowsay-3-8-3.cowsay  # This will be version 3.8.3
  ];
}
```

## Complete Example

Here's a full working example for pinning cowsay 3.8.3:

### flake.nix
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Pin cowsay to specific version
    nixpkgs-cowsay-3-8-3 = {
      url = "github:nixos/nixpkgs/abc123def456";  # Replace with actual hash
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs: {
    homeConfigurations = {
      "user@hostname" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        extraSpecialArgs = {
          inherit inputs;
          pkgs-cowsay-3-8-3 = import inputs.nixpkgs-cowsay-3-8-3 {
            system = "x86_64-linux";
          };
        };
        modules = [ ./home/user/hostname ];
      };
    };
  };
}
```

### home/user/hostname/default.nix
```nix
{
  pkgs,
  pkgs-cowsay-3-8-3,
  ...
}: {
  home.packages = [
    pkgs-cowsay-3-8-3.cowsay  # Version 3.8.3
  ];
}
```

## Verification

After rebuilding, verify the version:

```bash
# Check installed version
cowsay --version

# Check which nixpkgs revision it came from
nix-store -q --references $(which cowsay) | grep nixpkgs
```

## Best Practices

1. **Document why you're pinning**
   ```nix
   # Pin cowsay 3.8.3 because version 3.8.4 has a bug with unicode characters
   # See: https://github.com/...
   pkgs-cowsay-3-8-3.cowsay
   ```

2. **Use descriptive names**
   - Good: `nixpkgs-terraform-1-5-7`, `nixpkgs-nodejs-18`
   - Bad: `nixpkgs-old`, `nixpkgs-2`

3. **Keep pins minimal**
   - Only pin packages that truly need it
   - Consider if a newer version would work
   - Review pins periodically

4. **Set `flake = false` for efficiency**
   - Reduces closure size
   - Only use the packages, not the flake structure

5. **Pin at the package level, not system-wide**
   - Don't replace your entire nixpkgs
   - Only import specific packages from pinned revisions

## Alternative Approaches

### Package Override (For minor changes)

If you just need to override version/source, use overrides:

```nix
{
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.cowsay.overrideAttrs (old: {
      version = "3.8.3";
      src = pkgs.fetchFromGitHub {
        owner = "cowsay-org";
        repo = "cowsay";
        rev = "v3.8.3";
        sha256 = "...";
      };
    }))
  ];
}
```

**When to use:**
- Simple version/source changes
- Don't need to rebuild dependencies
- Want to keep same nixpkgs version for everything else

### Direct Derivation (For custom builds)

For complete control, write your own derivation:

```nix
{
  pkgs,
  ...
}: let
  cowsay-custom = pkgs.stdenv.mkDerivation {
    pname = "cowsay";
    version = "3.8.3";
    src = pkgs.fetchFromGitHub {
      owner = "cowsay-org";
      repo = "cowsay";
      rev = "v3.8.3";
      sha256 = "...";
    };
    # ... build instructions
  };
in {
  home.packages = [ cowsay-custom ];
}
```

**When to use:**
- Package not in nixpkgs
- Need significant customization
- Learning/understanding Nix packaging

## Troubleshooting

### Hash Mismatch
```
error: hash mismatch in fixed-output derivation
```
**Solution:** Update the sha256 hash or remove it to let Nix compute it.

### Package Doesn't Exist in That Revision
```
error: attribute 'cowsay' missing
```
**Solution:** The package didn't exist or had a different name in that revision. Try a different commit.

### Build Failures
**Solution:** Older packages may not build with newer dependencies. Consider:
- Using a closer revision
- Overriding dependencies
- Using binary cache if available

## Resources

### Version Search Tools
- [Nix Package Versions](https://lazamar.co.uk/nix-versions/) - Fast, simple version search
- [Nix Package History](https://history.nix-packages.com/search) - Comprehensive package database
- [NixHub](https://www.nixhub.io) - Modern UI with detailed info
- [nix_version_search_cli](https://github.com/jeff-hykin/nix_version_search_cli) - CLI search tool

### Documentation
- [nixpkgs GitHub](https://github.com/NixOS/nixpkgs) - Browse source and commits
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Deep dive into Nix
- [nix.dev](https://nix.dev/) - Official Nix documentation
- [NixOS Wiki](https://nixos.wiki/) - Community documentation
