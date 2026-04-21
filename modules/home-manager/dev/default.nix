{
  lib,
  pkgs,
  ...
}: let
  # nixpkgs has 0.25.10; nvim 0.12 requires >= 0.26.8
  # To update hashes: change version, then run:
  #   curl -sL <url> -o /tmp/ts.gz && nix-hash --type sha256 --flat /tmp/ts.gz | xargs nix-hash --type sha256 --to-base32
  # Prefix the output with "sha256:" below.
  tree-sitter-bin = let
    version = "0.26.8";
    sources = {
      "x86_64-linux" = {
        url = "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-linux-x64.gz";
        hash = "sha256:0vhkz8lvvn44ng77l6k59vii3is799xigpw24wap1fgh00la6m4p";
      };
      "aarch64-darwin" = {
        url = "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-macos-arm64.gz";
        hash = "sha256:17l8fnapvcy0g5n12vi3w2xwh8xgnk9f9ga15pb28dbj6kp2qkh2";
      };
    };
    source = sources.${pkgs.stdenv.hostPlatform.system};
  in
    pkgs.stdenv.mkDerivation {
      pname = "tree-sitter";
      inherit version;
      src = pkgs.fetchurl {
        inherit (source) url hash;
      };
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/bin
        gunzip -c $src > $out/bin/tree-sitter
        chmod +x $out/bin/tree-sitter
      '';
    };
in {
  # Packages that require configuration get placed in relevant place
  # k9s is conditionally imported for darwin in its own module definition
  imports = [
    ../programs/k9s
  ];

  # Ensure common packages are installed
  home.packages = with pkgs;
    [
      # Packages that don't require configuring
      devenv
      go
      grepcidr
      powershell
      shellcheck
      yamllint

      # NVIM specific requirements
      ######
      #nvim_0.12 requires treesitter-cli binary
      tree-sitter-bin
      # markdown conform requirement
      markdownlint-cli2

      #lsp requirements
      ## lua
      copilot-language-server
      lua-language-server
      stylua
      lua # Lua runtime for pre-commit
      luarocks # Lua package manager for pre-commit
      luaPackages.luacheck # Lua linter for pre-commit
      ## nix
      alejandra
      nixd
      ## go
      gopls

      #linting
      ## go
      golangci-lint
      golangci-lint-langserver
      ## nix
      deadnix
      statix

      # pre-commit tools (cross-platform)
      pre-commit
      codespell # Spell checker for pre-commit

      powershell-editor-services

      # Terraform
      terraform-ls
      # also used in pre-commit
      tflint
    ]
    ++ lib.optionals stdenv.isDarwin [
      (azure-cli.withExtensions [azure-cli.extensions.aks-preview])
      github-copilot-cli
      fluxcd
      kubectl
      python313Packages.pip
      stable.kubelogin
      terraform

      # pre-commit requirements (Darwin-specific)
      # https://github.com/antonbabenko/pre-commit-terraform
      # Use stable channel for checkov until pyarrow/protobuf issue is resolved
      # See: https://github.com/nixos/nixpkgs/issues/461396
      # TODO: Switch back to 'checkov' when issue is resolved (check PR #461569, #461572)
      stable.checkov
      terraform-docs
      terragrunt
    ];
}
