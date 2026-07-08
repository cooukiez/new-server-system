/*
modules/services/default.nix

part of server system
created 2026-05-13 by ludw
*/
{
  imports = [
    ./mail-archiver
    ./opengist
    ./papra

    ./metrics.nix
  ];
}
