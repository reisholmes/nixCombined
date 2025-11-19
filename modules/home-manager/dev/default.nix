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
      go
      powershell
      shellcheck
      yamllint

      # NVIM specific requirements
      ######
      # markdown conform requirement
      markdownlint-cli2

      #lsp requirements
      ## lua
      lua-language-server
      stylua
      ## nix
      alejandra
      nixd

      powershell-editor-services

      # Terraform
      terraform-ls
      # also used in pre-commit
      tflint
    ]
    ++ lib.optionals stdenv.isDarwin [
      (azure-cli.withExtensions [azure-cli.extensions.aks-preview])
      fluxcd
      kubectl
      stable.kubelogin
      terraform

      # pre-commit requirements
      # https://github.com/antonbabenko/pre-commit-terraform
      # Use stable channel for checkov until pyarrow/protobuf issue is resolved
      # See: https://github.com/nixos/nixpkgs/issues/461396
      # TODO: Switch back to 'checkov' when issue is resolved (check PR #461569, #461572)
      stable.checkov
      pre-commit
      terraform-docs
      terragrunt
    ];
}
