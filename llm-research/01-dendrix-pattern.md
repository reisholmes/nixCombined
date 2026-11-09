# 01 - The Dendritic pattern and Dendrix

Status: Done. Sources at the bottom; every claim traces to a fetched doc or file.

## Naming

- Dendritic: the pattern. Every .nix file under modules/ is a flake-parts module, auto-loaded. The docs call it "not a library nor a framework".
- Dendrix: the community distribution on top of the pattern, a registry of shareable flake-parts modules, comparable to NUR but for flake-parts.
- The two are separable. A repo can use the pattern with zero dependency on the Dendrix registry.

## Core terms (as the docs define them)

- class: a configuration type, for example nixos, darwin, homeManager, nixvim.
- aspect: a cross-cutting feature configured across one or more classes, usually via the flake-parts option flake.modules.<class>.<aspect>.
- per-file modules: all .nix files under modules/ are flake-parts modules. import-tree loads them automatically, and paths containing /_ are ignored. No manual import lists.
- no specialArgs: values shared across classes go through let bindings or flake-level options. The docs call specialArgs/extraSpecialArgs an anti-pattern.
- feature-centric, not host-centric: hosts select aspects instead of importing files. Example from the docs:

  ```nix
  flake.nixosConfigurations.my-host.modules =
    with inputs.self.modules.nixos; [ ai ssh vpn ];
  ```

- feature closures: everything for one feature lives in one unit.
- incremental features: add or remove a file to enable or disable a feature. Prefix a file with _ to disable it.

## The minimal flake

The canonical shape, straight from the docs and confirmed in jackjohn7/nixconf:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
    (inputs.import-tree ./modules);
}
```

Hosts become data: a host file declares facts (system, form, cpu, gpu, desktops) and feature modules attach via at predicates, for example when (s: s.host.gpu == "nvidia").

## Getting started (adopting an existing flake)

1. Add inputs for flake-parts and import-tree.
2. Move configuration into modules/, one module per file or directory.
3. Replace the flake body with the two-line outputs above.
4. Optionally add the registry: inputs.dendrix.url = "github:vic/dendrix", then import trees or layers in a module, e.g. imports = [ inputs.dendrix.vic-vix.macos-keys ].
5. For a fresh setup the docs offer nix flake init github:vic/dendrix#template.

## Compatibility

- home-manager: first-class. The docs use flake.modules.homeManager.<aspect> throughout, and the repo tags a home-manager topic.
- nix-darwin (macOS): first-class. flake.modules.darwin.<aspect> and darwinConfigurations appear in the docs.
- Not NixOS-only. The FAQ says Dendrix is "more a flake-parts configurations collection that can be included on any dendritic setup", though it does not provide bootable NixOS installers.
- Not documented: an explicit platform support matrix, WSL specifics, or macOS use without nix-darwin.

## The Dendrix registry

- It exposes inputs.dendrix.<repo> (the repo's shared subtree as an import-tree) and inputs.dendrix.<repo>.<aspect>. Trees support flag filters, e.g. inputs.dendrix.your-repo.flagged "-emacs +vim".
- Layers are blessed cross-repo flake-parts modules under dev/layers/<name>/modules in the Dendrix repo.
- Only vic-vix is explicitly registered today. Seven other repos exist as discovery-cache entries only.
- The docs are candid: community trees "are just references to sub-trees of people's repositories" with "no guarantees of things working", and unmaintained files get removed.
- Convention: a modules/community directory is the shareable subtree. Any path containing a private infix is not shared.

## Fourth example: adumh00man/dendritic-tutorial

Companion repo to a YouTube series (`git.voidarc.co.uk/adumh00man/dendritic-tutorial`, Gitea). Minimal, NixOS-only, deliberately partial.

- Stock two-line `outputs`, inputs are nixpkgs + flake-parts + import-tree + nvim + wrappers.
- Host files are just a module list: `flake.nixosConfigurations.<host>.modules = with self.nixosModules; [ hostConfiguration system zsh ]` plus optional inline override objects. No predicates, no `at` auto-attach. This is the simplest composition style, and it is what our repo should target.
- `system/default.nix` is a collection module with a warning not to import a collection and its children together.
- Notable tricks: `moduleWithSystem` for `self'` access, `_module.args` inside `perSystem` to inject `unfreePkgs`/`unstablePkgs`, `_`-prefixed files skipped by import-tree (manual import for `_hardware-configuration.nix`), a feature shipping its own package consumed via a `nixpkgs.overlays` swap, and nix-community/nix-wrapper-modules for alias-based wrappers.
- Gap for us: no home-manager, no nix-darwin. Every class used is nixos*. Our exact repo shape is still only shown by vimjoyer's dendritic-home-manager example.

## What vimjoyer's videos actually recommend

- "Elevate Your Nix Config With Dendritic Pattern" (2026-01-27, youtube -TRbzkw6Hjs): teaches the pattern with a minimal template (nixpkgs + flake-parts + import-tree only). Full code at https://vimjoyer.com/nix/dendritic.
- "Ultimate NixOS Desktop: Niri, Noctalia Shell, and the Dendritic Pattern" (2026-03-22, youtube aNgujRXDTdE): applies the pattern to a full NixOS desktop.
- Home-manager example: https://vimjoyer.com/nix/dendritic-home-manager reuses one home-manager module both as a standalone homeConfigurations profile and inside a NixOS config. That is beyond what the official Dendrix docs show, and it matches our repo's shape.
- No video names the Dendrix registry. He teaches the pattern plus his own templates. The registry is optional sugar, not the core recommendation.

## Complications to weigh

- vic/vix, the flagship example, has migrated off flake-parts to "Ren" (github:vic/ren, "a re-take on Den"). Its flake.nix is now generated. So the most prominent example of the pattern is moving to a successor tool.
- The community layer is young (one registered repo).
- Related ecosystem if the pattern matures in a specific direction: vic/den, vic/flake-file, vic/flake-aspects, quasigod/unify.

## Bottom line for us

- The pattern fits our repo exactly: home-manager and darwin are first-class, hosts become data, and the specialArgs threading in our flake disappears into flake-level options.
- The registry does not fit us yet: we have one user and three hosts, and no need to consume or share aspects cross-repo.

## Sources

- https://dendrix.denful.dev/index.html (intro, NUR comparison)
- https://dendrix.denful.dev/Dendritic.html (core pattern, class/aspect, composition example)
- https://dendrix.denful.dev/Getting-Started.html (inputs, init template)
- https://dendrix.denful.dev/Dendrix-Trees.html (trees, flags, no-guarantees quote)
- https://dendrix.denful.dev/Dendrix-Layers.html (layers)
- https://dendrix.denful.dev/Dendrix-Conventions.html (community/private conventions)
- https://dendrix.denful.dev/Dendritic-Ecosystem.html (vic/den, flake-file, unify, dendrite)
- https://github.com/denful/dendrix (templates/default, registry code)
- https://github.com/jackjohn7/nixconf (pattern without registry)
- https://github.com/vic/vix (flagship, now on Ren)
- https://www.youtube.com/watch?v=-TRbzkw6Hjs ; https://vimjoyer.com/nix/dendritic
- https://vimjoyer.com/nix/dendritic-home-manager (home-manager example)
- https://git.voidarc.co.uk/adumh00man/dendritic-tutorial (+ raw files: flake.nix, modules/, hosts/, features/, system/)
