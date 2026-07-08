/*
modules/services/mail-archiver/default.nix

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
    ./maintenance.nix
  ];

  options.containerServices.mail-archiver = {
    maintenance = mkEnableDefault;
  };
}
