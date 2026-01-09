{
  config,
  lib,
  nixgl,
  ...
}: let
  cfg = config.nixgl;
in {
  options.nixgl = {
    enable = lib.mkEnableOption "NixGL configuration for non-NixOS systems";

    profile = lib.mkOption {
      type = lib.types.enum ["nvidia" "mesa" "nvidiaPrime"];
      default = "mesa";
      description = ''
        NixGL hardware profile to use:
        - nvidia: For systems with NVIDIA graphics (enables Vulkan)
        - mesa: For systems with Intel/AMD graphics
        - nvidiaPrime: For NVIDIA Optimus/Prime laptops (uses mesa as default, nvidia as offload)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    targets.genericLinux.nixGL = {
      packages = nixgl.packages;

      defaultWrapper =
        if cfg.profile == "nvidia"
        then "nvidia"
        else "mesa";

      offloadWrapper = lib.mkIf (cfg.profile == "nvidiaPrime") "nvidiaPrime";

      vulkan.enable = cfg.profile == "nvidia";
    };
  };
}
