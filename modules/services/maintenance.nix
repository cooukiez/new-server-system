/*
  modules/services/maintenance.nix

  part of server system
  created 2026-04-20
*/

{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.containerMaintenance;

  mkEnableDefault = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
in
{
  options.containerMaintenance = {
    papra = mkEnableDefault;
  };

  config = {
    # papra maintenance configuration
    systemd.services.papra-db-maintenance =
      let
        papraMaintenanceScript = pkgs.writeShellScript "papra-db-update" ''
          set -e
          SYSTEMCTL="${pkgs.systemd}/bin/systemctl"
          SQLITE="${pkgs.sqlite}/bin/sqlite3"
          DB_PATH="/opt/papra/data/db/db.sqlite"

          $SYSTEMCTL --user -M squ@.host stop papra.service
          $SQLITE "$DB_PATH" "UPDATE documents SET original_name = 'none';"
          $SYSTEMCTL --user -M squ@.host start papra.service
        '';
      in
      lib.mkIf cfg.papra {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${papraMaintenanceScript}";
          User = "root";
        };
      };

    # papra maintenance timer
    systemd.timers.papra-db-maintenance = lib.mkIf cfg.papra {
      timerConfig = {
        OnCalendar = "*-*-* 03:00:00";
        Persistent = true;
        Unit = "papra-db-maintenance.service";
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
