/*
  modules/nixos/default.nix

  part of der-home-server
  created 2026-04-02
*/

{
  # list module files here
  common = import ./common;
  services = import ./services;
}
