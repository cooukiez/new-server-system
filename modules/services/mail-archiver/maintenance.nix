/*
modules/services/mail-archiver/maintenance.nix

part of server system
created 2026-07-08 by ludw
*/
{
  config,
  pkgs,
  lib,
  hostConfig,
  ...
}: let
  cfg = config.containerServices.mail-archiver;
in {
  age.secrets.archiver-db-pass.file = ../../../secrets/containers/archiver/s_db-pass.age;

  systemd.services.mail-archiver-maintenance = lib.mkIf cfg.maintenance {
    description = "Mail-Archiver Maintenance";
    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";
      User = "root";

      Environment = [
        "MAIL_ARCHIVER_DB_USER=admin"
        "MAIL_ARCHIVER_DB_PASS_PATH=${config.age.secrets.archiver-db-pass.path}"
        "MAIL_ARCHIVER_DB_HOST=127.0.0.1"
        "MAIL_ARCHIVER_DB_PORT=${toString hostConfig.ports.mailArchiverDb}"
      ];

      ExecStart = [
        "+${pkgs.writeShellScript "mail-archiver-maintenance" ''
          ${pkgs.python3.withPackages (ps: with ps; [psycopg2])}/bin/python3 ${./maintenance.py} --dry-run
        ''}"
      ];
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
