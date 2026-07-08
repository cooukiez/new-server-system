/*
modules/services/default.nix

part of server system
created 2026-05-13 by ludw
*/
{pkgs, ...}: let
  convert-to-opus = pkgs.writeShellScriptBin "convert-to-opus" (builtins.readFile ./scripts/convert-to-opus.sh);
  migrate-db = pkgs.writeShellScriptBin "migrate-db" (builtins.readFile ./scripts/migrate-db.sh);
in {
  imports = [
    ./maintenance.nix
    ./metrics.nix
    ./papra-export.nix
  ];

  environment.systemPackages = [
    convert-to-opus
    migrate-db
  ];
}
