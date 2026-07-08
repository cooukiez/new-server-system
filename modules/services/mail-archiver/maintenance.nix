{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.containerServices.mail-archiver;
in {
  systemd.services.mail-archiver-maintenance = let
    mailArchiverMaintenanceScript = pkgs.writeShellScript "mail-archiver-maintenance" ''

    '';
  in
    lib.mkIf cfg.maintenance {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${mailArchiverMaintenanceScript}";
        User = "root";
      };
    };

  systemd.timers.mail-archiver-maintenance = lib.mkIf cfg.maintenance {
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      Unit = "mail-archiver-maintenance.service";
    };

    wantedBy = ["timers.target"];
  };
}
