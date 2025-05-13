{
  nhModules,
  pkgs,
  ...
}: {
  imports = [
    "${nhModules}/common"
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";

  # Packages specific to this
  home.packages = with pkgs; [coolercontrol coolercontrold coolercontrol-liqctld];
}
