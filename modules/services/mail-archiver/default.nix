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
