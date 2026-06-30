/*
modules/services/exporter.nix

part of server system
created 2026-06-29 by ludw
*/
{
  config,
  pkgs,
  lib,
  ...
}:
let
  exporterScript = pkgs.writers.writeTypeScript "papra-exporter.ts" ./scripts/papra-exporter.ts;
  in
{
  age.secrets.papra-download.file = ../../secrets/papra-download.age;

  systemd.services.papra-exporter =
    lib.mkIf cfg.papra {
      description = "Export Papra documents";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";

        Environment = [
          "PAPRA_API_KEY_PATH=${config.age.secrets.papra-download.path}"
        ];

        ExecStart = [
          "+${pkgs.writeShellScript "papra-export" ''
            ${pkgs.bun}/bin/bun run ${exporterScript} --org org_epgl80n46kblsqfih852xtqy --folder /data/documents-backup/general-ludwig
          ''}"
        ];
      };
    };

  systemd.timers.papra-exporter = lib.mkIf cfg.papra {
    timerConfig = {
      OnCalendar = "*-*-* 03:15:00";
      Persistent = true;
      Unit = "papra-exporter.service";
    };
    wantedBy = ["timers.target"];
  };
}