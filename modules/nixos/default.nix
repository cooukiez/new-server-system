/*
  modules/nixos/default.nix

  part of der-home-server
  created 2026-04-02
*/

{
  common = import ./common;
  core = import ./core;
  services = import ./services;
}
