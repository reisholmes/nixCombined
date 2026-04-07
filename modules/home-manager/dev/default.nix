{
  lib,
  pkgs,
  ...
}: let
  # nixpkgs has 0.25.10; nvim 0.12 requires >= 0.26.8
  tree-sitter-bin = pkgs.stdenv.mkDerivation rec {
    pname = "tree-sitter";
    version = "0.26.8";
    src = pkgs.fetchurl {
      url = "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-linux-x64.gz";
      # To update: change version, then run:
      #   nix-prefetch-url https://github.com/tree-sitter/tree-sitter/releases/download/v<VERSION>/tree-sitter-linux-x64.gz
      # Prefix the output with "sha256:" below.
      hash = "sha256:0vhkz8lvvn44ng77l6k59vii3is799xigpw24wap1fgh00la6m4p";
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
    ++ lib.optionals (!stdenv.isDarwin) [
      tree-sitter-bin # nvim 0.12 requires tree-sitter >= 0.26.8
    ]
    ++ lib.optionals stdenv.isDarwin [
      (azure-cli.withExtensions [azure-cli.extensions.aks-preview])
      github-copilot-cli
      fluxcd
      kubectl
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
