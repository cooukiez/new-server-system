/*
  modules/containers/service-config.nix

  part of der-home-server
  created 2026-04-19
*/

{
  config,
  lib,
  ...
}:
let
  homeDir = config.home.homeDirectory;
in
{
  options.myServices = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, name, ... }:
        let
          serviceName = name;
        in
        {
          options = {
            serviceConfig = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule (
                  { config, ... }:
                  {
                    options = {
                      serviceName = lib.mkOption {
                        type = lib.types.str;
                        default = serviceName;
                        readOnly = true;
                      };

                      name = lib.mkOption {
                        type = lib.types.str;
                        default = serviceName;
                      };

                      description = lib.mkOption { type = lib.types.str; };

                      serviceType = lib.mkOption {
                        type = lib.types.enum [
                          "Apps"
                          "Restricted"
                          "Networking"
                          "Monitoring"
                          "Services"
                        ];

                        default = "Apps";
                      };

                      port = lib.mkOption { type = lib.types.int; };

                      subdomain = lib.mkOption {
                        type = lib.types.str;
                        default = "subdomain";
                      };

                      domain = lib.mkOption {
                        type = lib.types.str;
                        default = "${config.subdomain}.home.lan";
                        readOnly = true;
                      };

                      href = lib.mkOption {
                        type = lib.types.str;
                        default = "https://${config.domain}";
                        readOnly = true;
                      };

                      policy = lib.mkOption {
                        type = lib.types.enum [
                          "bypass"
                          "one_factor"
                          "two_factor"
                        ];

                        default = "one_factor";
                      };

                      group = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                      };

                      icon = lib.mkOption { type = lib.types.str; };
                    };
                  }
                )
              );

              default = null;
            };
          };
        }
      )
    );

    default = { };
  };
}
