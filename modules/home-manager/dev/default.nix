{pkgs, ...}: {
  # Packages that require configuration get placed in relevant place
  imports = [
    #../scripts
  ];

  # Ensure common packages are installed
  home.packages = with pkgs; [
    # Packages that don't require configuring
    (azure-cli.withExtensions [azure-cli.extensions.aks-preview])
    fluxcd
    kubectl
    kubelogin
    powershell
    yamllint

    # pre-commit requirements
    # hgttps://github.com/antonbabenko/pre-commit-terraform
    checkov
    pre-commit
    terraform-docs
    terragrunt
  ];
}
