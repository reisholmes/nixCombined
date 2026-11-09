# What: Timer-only nix GC: deletes generations older than 21 days and optimises the store.
# Used by: Imported by home-manager/systemd/default.nix.
# Note: Timer-only on purpose. A oneshot in default.target restarts on every switch, see llm-notes/home-manager-rebuild.md.
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
