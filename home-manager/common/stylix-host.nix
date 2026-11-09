{
  config,
  lib,
  ...
}: let
  cfg = config.stylix.hostConfig;
in {
  options.stylix.hostConfig = {
    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to wallpaper image for this host. Set to null to skip wallpaper configuration (e.g., for work machines).";
      example = lib.literalExpression "../../../modules/home-manager/assets/stylix/wallpaper_wave_mac.jpg";
    };

    autoEnable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic theming for supported applications";
    };
  };

  config = lib.mkIf config.stylix.enable {
    stylix = lib.mkMerge [
      {
        autoEnable = lib.mkDefault cfg.autoEnable;
      }
      (lib.mkIf (cfg.wallpaper != null) {
        image = cfg.wallpaper;
      })
    ];
  };
}
