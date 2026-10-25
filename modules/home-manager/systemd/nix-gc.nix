# Nix store garbage collection (Linux only)
#
# Mirrors the macOS nix-darwin auto-GC in modules/darwin/common/default.nix
# (--delete-older-than 21d, plus optimise), adapted for a desktop that is not
# left on overnight:
#   - runs at every login (WantedBy = default.target)
#   - a Mon 11:00 timer catches up on the rare days the machine is left on
#
# User-level systemd units, so home-manager can manage them without root.
{
  lib,
  pkgs,
  ...
}: let
  gcScript = pkgs.writeShellScriptBin "nix-gc-weekly" ''
    # nix-collect-garbage performs the store GC internally and honours
    # --delete-older-than; nix-store --gc does NOT take that flag.
    ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 21d
    ${pkgs.nix}/bin/nix-store --optimise
  '';
in
  lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    systemd.user = {
      # Runs at every login; the timer also triggers it.
      services."nix-gc" = {
        Unit.Description = "Nix store garbage collection";
        Install.WantedBy = ["default.target"];
        Service = {
          Type = "oneshot";
          ExecStart = "${gcScript}/bin/nix-gc-weekly";
        };
      };
      # Safety net for the rare days the machine is left on.
      timers."nix-gc" = {
        Unit.Description = "Scheduled Nix garbage collection";
        Timer = {
          OnCalendar = "Mon 11:00:00";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  }
