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
              description = "Public service configuration";
              default = null;
              type = lib.types.nullOr (
                lib.types.submodule (
                  { config, ... }:
                  {
                    options = {
                      serviceName = lib.mkOption {
                        type = lib.types.str;
                        readOnly = true;
                        default = serviceName;
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
                        description = "The category this service belongs to on the homepage";
                      };

                      port = lib.mkOption { type = lib.types.int; };

                      subdomain = lib.mkOption {
                        type = lib.types.str;
                        default = "subdomain";
                        description = "The external subdomain for the service";
                      };

                      domain = lib.mkOption {
                        type = lib.types.str;
                        readOnly = true;
                        default = "${config.subdomain}.home.lan";
                        description = "The external domain for the service (read-only)";
                      };

                      href = lib.mkOption {
                        type = lib.types.str;
                        readOnly = true;
                        default = "https://${config.domain}";
                        description = "The external URL for the service (read-only)";
                      };

                      policy = lib.mkOption {
                        type = lib.types.enum [
                          "bypass"
                          "one_factor"
                          "two_factor"
                        ];
                        default = "one_factor";
                        description = "Auth policy for the reverse proxy";
                      };

                      group = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "LDAP group allowed to access this service";
                      };

                      icon = lib.mkOption { type = lib.types.str; };
                    };
                  }
                )
              );
            };

            containerConfig = {
              files = lib.mkOption {
                description = "Configuration files for the container";
                default = { };
                type = lib.types.attrsOf (
                  lib.types.submodule (
                    { config, name, ... }:
                    {
                      options = {
                        name = lib.mkOption {
                          type = lib.types.str;
                          default = name;
                        };

                        source = lib.mkOption {
                          type = lib.types.either lib.types.path lib.types.package;
                          description = "The source path or generated file derivation";
                        };

                        path = lib.mkOption {
                          type = lib.types.str;
                          readOnly = true;
                          default = "containers/${serviceName}/${config.name}";
                          description = "The relative path in home directory where the file is stored (read-only)";
                        };

                        fullPath = lib.mkOption {
                          type = lib.types.str;
                          readOnly = true;
                          default = "${homeDir}/${config.path}";
                          description = "The absolute path where the file is stored (read-only)";
                        };

                        copyToVolume = lib.mkOption {
                          description = "List of volumes to copy the file to";
                          default = [ ];
                          type = lib.types.listOf (
                            lib.types.submodule {
                              options = {
                                volume = lib.mkOption {
                                  type = lib.types.str;
                                  description = "The target volume name or pate";
                                  example = "/opt/service/volume";
                                };

                                mode = lib.mkOption {
                                  type = lib.types.str;
                                  default = "0644";
                                  description = "The permissions mode for chmod";
                                  example = "0644";
                                };
                              };
                            }
                          );
                        };
                      };
                    }
                  )
                );
              };

              volumes = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = { };
                description = "Mapping of volume names to host paths";

                example = {
                  volume-data = "/opt/service/volume";
                };
              };
            };
          };
        }
      )
    );

    default = { };
  };
}
