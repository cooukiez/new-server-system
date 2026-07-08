/*
modules/services/opengist/default.nix

part of server system
created 2026-07-08 by ludw
*/
{lib, ...}: let
  mkEnableDefault = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
in {
  imports = [
    ./export.nix
  ];

  options.containerServices.opengist = {
    export = mkEnableDefault;
  };
}
