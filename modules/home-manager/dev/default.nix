{
  lib,
  pkgs,
  ...
}: let
  system = builtins.currentSystem or "x86_64-linux"; # Fallback if not set
  isDarwin = builtins.match ".*-darwin" system != null;
in {
  # Packages that require configuration get placed in relevant place
  imports =
    [
      #../scripts
    ]
    ++ lib.optionals isDarwin [
      ../programs/k9s
    ];

  # Ensure common packages are installed
  home.packages = with pkgs;
    [
      # Packages that don't require configuring
      go
      powershell
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
      kubelogin
      terraform

      # pre-commit requirements
      # hgttps://github.com/antonbabenko/pre-commit-terraform
      checkov
      pre-commit
      terraform-docs
      terragrunt
    ];
}
