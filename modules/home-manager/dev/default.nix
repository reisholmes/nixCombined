{
  lib,
  pkgs,
  ...
}: {
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

      # nix linting
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
