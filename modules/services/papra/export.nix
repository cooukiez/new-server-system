/*
modules/services/papra/export.nix

part of server system
created 2026-06-29 by ludw
*/
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.containerServices.papra;
in {
  age.secrets.papra-download.file = ../../../secrets/papra-download.age;

  systemd.services.papra-exporter = lib.mkIf cfg.export {
    description = "Export Papra documents";
    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";
      User = "root";

      Environment = [
        "PAPRA_API_KEY_PATH=${config.age.secrets.papra-download.path}"
      ];

      ExecStart = [
        "+${pkgs.writeShellScript "papra-export" ''
          ${pkgs.coreutils}/bin/rm -rf /data/documents-backup
          ${pkgs.coreutils}/bin/mkdir -p /data/documents-backup

          ${pkgs.bun}/bin/bun run ${./export.ts} --org org_epgl80n46kblsqfih852xtqy --folder /data/documents-backup/general-ludwig

          ${pkgs.coreutils}/bin/chown -R admin:users /data/documents-backup
        ''}"
      ];
    };
  };

  systemd.timers.papra-exporter = lib.mkIf cfg.export {
    timerConfig = {
      OnCalendar = "*-*-* 03:15:00";
      Persistent = true;
      Unit = "papra-exporter.service";
    };
    wantedBy = ["timers.target"];
  };
}
