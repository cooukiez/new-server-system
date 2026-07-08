/*
modules/services/default.nix

part of server system
created 2026-05-13 by ludw
*/
{pkgs, ...}: let
  migrate-db = pkgs.writeShellScriptBin "migrate-db" (builtins.readFile ./scripts/migrate-db.sh);
in {
  imports = [
    ./mail-archiver
    ./opengist
    ./papra

    ./metrics.nix
  ];

  environment.systemPackages = [
    migrate-db
  ];
}
