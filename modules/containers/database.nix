/*
modules/containers/database.nix

part of server system
created 2026-05-13 by ludw
*/
{
  config,
  pkgs,
  images,
  ports,
  ...
}: let
in {
  myServices.postgres = {
    serviceConfig = {
      name = "Postgres DB";
      description = "Centralized Relational Database";
      serviceType = "Services";

      subdomain = "db";
      port = ports.pgadmin;

      policy = "bypass";

      icon = "postgresql";
    };
  };

  age.secrets = let
    mkSecret = name: {
      file = ../../secrets/${name}.age;
      mode = "444";
    };
  in {
    pgadmin-pw = mkSecret "db/s_pgadmin-pw";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    networks.postgres-net = {
      networkConfig = {
        internal = false;
      };
    };

    volumes.pgadmin-data.volumeConfig = {
      type = "bind";
      device = "/opt/postgres/pgadmin";
    };

    containers.pgadmin = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.pgadmin}";
        name = "pgadmin";
        networks = [networks.postgres-net.ref];

        environments = {
          TZ = "Europe/Berlin";

          PGADMIN_DEFAULT_EMAIL = "management.homeserver@mailbox.org";
          PGADMIN_DEFAULT_PASSWORD_FILE = "/run/secrets/PGADMIN_PASSWORD";

          PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION = "True";
          PGADMIN_CONFIG_CONSOLE_LOG_LEVEL = "10";

          PGADMIN_LISTEN_ADDRESS = "0.0.0.0";
          PGADMIN_LISTEN_PORT = "80";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          # secrets
          "${config.age.secrets.pgadmin-pw.path}:/run/secrets/PGADMIN_PASSWORD:ro"

          # volumes
          "${volumes.pgadmin-data.ref}:/var/lib/pgadmin:U"
        ];

        publishPorts = [
          "${toString ports.pgadmin}:80/tcp"
        ];
      };
    };
  };
}
