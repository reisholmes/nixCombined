{nhModules, ...}: {
  imports = [
    "${nhModules}/common"
    "${nhModules}/programs/neovim"
    "${nhModules}/services/waybar"
  ];
}
