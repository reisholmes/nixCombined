# Nix store garbage collection (Linux only)
#
# Mirrors the macOS nix-darwin auto-GC in modules/darwin/common/default.nix
# (--delete-older-than 21d, plus optimise), adapted for a desktop that is not
# left on overnight:
#   - a Mon 11:00 timer catches up on the rare days the machine is left on
#
# Not wanted by default.target: home-manager's reloadSystemd activation would
# then restart the finished oneshot on every `home-manager switch`, running a
# full GC scan on every rebuild. The timer alone covers the intent.
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
      # Timer-only: started on demand by the nix-gc timer.
      services."nix-gc" = {
        Unit.Description = "Nix store garbage collection";
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
