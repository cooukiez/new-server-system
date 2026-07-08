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
