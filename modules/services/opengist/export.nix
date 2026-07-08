{
  config,
  pkgs,
  lib,
  hostConfig,
  ...
}: let
  cfg = config.containerServices.opengist;
in {
  age.secrets.opengist-db-pass.file = ../../../secrets/containers/opengist/s_db-pass.age;

  systemd.services.opengist-exporter = lib.mkIf cfg.export {
    description = "Export Gists from Opengist";
    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";
      User = "root";

      Environment = [
        "OPENGIST_DB_USER=admin"
        "OPENGIST_DB_PASS_PATH=${config.age.secrets.opengist-db-pass.file}"
        "OPENGIST_DB_HOST=127.0.0.1"
        "OPENGIST_DB_PORT=${toString hostConfig.ports.opengistDb}"
      ];

      ExecStart = [
        "+${pkgs.writeShellScript "opengist-export" ''
          ${pkgs.python3}/bin/python3 ${./export.py} --gists-dir /opt/opengist/data/repos/ludwig --export-dir /data/gists-backup
          ${pkgs.coreutils}/bin/chown -R admin:users /data/gists-backup
        ''}"
      ];
    };
  };

  systemd.timers.opengist-exporter = lib.mkIf cfg.export {
    timerConfig = {
      OnCalendar = "*-*-* 03:15:00";
      Persistent = true;
      Unit = "opengist-exporter.service";
    };
    wantedBy = ["timers.target"];
  };
}
