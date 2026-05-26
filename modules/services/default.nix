/*
modules/services/default.nix

part of server system
created 2026-05-13 by ludw
*/
{
  imports = [
    ./maintenance.nix
    ./metrics.nix
  ];
}
