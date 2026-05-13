/*
modules/services/default.nix

part of server system
created 2026-05-10
*/
{
  imports = [
    ./maintenance.nix
    ./metrics.nix
  ];
}
