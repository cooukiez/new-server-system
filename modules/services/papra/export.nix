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
          ${pkgs.bun}/bin/bun run ${./export.ts} --org org_to3j3xq92h8v5zm3o493u27t --folder /data/documents-backup/kkg-ludwig
          ${pkgs.bun}/bin/bun run ${./export.ts} --org org_ja752yex0x69vhfddhrlt0bg --folder /data/documents-backup/media-ludwig
          ${pkgs.bun}/bin/bun run ${./export.ts} --org org_ymzlf04ao0ln1l3o14m2inpj --folder /data/documents-backup/redi-ludwig
          ${pkgs.bun}/bin/bun run ${./export.ts} --org org_dmo2ojori88q2duv1addgapn --folder /data/documents-backup/urkunden-ludwig

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
