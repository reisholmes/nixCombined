{
  # I essentially copied this from someone much smarter than me:
  # https://github.com/AlexNabokikh/nix-config
  # All I wanted was a simple, easy enough to follow examples, of managing
  # two machines (linux mint and mac, in my case) with home manager and
  # shared app configs between them. Alex's config matches what I required.
  # If you don't follow what I'm doing then go read his repo.
  description = "Nix and nix-darwin configs for my machines";
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix Darwin (for MacOS machines)
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";

    # Stylix is a theming framework for NixOS, Home Manager, nix-darwin, and
    # Nix-on-Droid that applies color schemes, wallpapers, and
    # fonts to a wide range of applications.
    stylix.url = "github:danth/stylix";
    stylix-stable.url = "github:danth/stylix/release-25.11";

    # Pre-commit hooks for code quality checks
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dendritic pattern: flake-parts module system plus automatic module loading.
    # Inert until outputs switch to mkFlake + import-tree (see llm-research/04-migration-plan.md).
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;}
    (inputs.import-tree ./modules);
}
