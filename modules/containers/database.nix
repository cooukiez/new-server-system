/*
  modules/containers/database.nix

  part of der-home-server
  created 2026-04-16
*/

{
  config,
  pkgs,
  ports,
  ...
}:
let
  postgresVersion = "alpine";
  pgadminVersion = "latest";

  services = [
    {
      name = "authelia";
      user = "admin";
      dbs = [ "authelia" ];
    }
    {
      name = "lldap";
      user = "lldap";
      dbs = [ "lldap" ];
      pass = "lldap";
    }


    {
      name = "atuin";
      user = "atuin";
      dbs = [ "atuin" ];
      pass = "atuin";
    }
    {
      name = "gitea";
      user = "gitea";
      dbs = [ "gitea" ];
      pass = "gitea";
    }
    {
      name = "ebk";
      user = "ebk";
      dbs = [ "ebk" ];
      pass = "ebk";
    }
    {
      name = "open-archiver";
      user = "archiver";
      dbs = [ "open-archiver" ];
      pass = "archiver";
    }
    {
      name = "linkwarden";
      user = "linkwarden";
      dbs = [ "linkwarden" ];
      pass = "linkwarden";
    }

    {
      name = "lidarr";
      user = "lidarr";
      dbs = [
        "lidarr-main"
        "lidarr-log"
      ];
      pass = "lidarr";
    }
  ];

  mkSql = service: ''
    -- Configuration for ${service.name}
    ${
      if service ? pass then
        ''
          DO $$ 
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${service.user}') THEN
              CREATE USER ${service.user} WITH PASSWORD '${service.pass}';
            END IF;
          END $$;''
      else
        ""
    }

    ${builtins.concatStringsSep "\n" (
      map (db: ''
        -- Database: ${db}
        SELECT 'CREATE DATABASE "${db}"' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${db}')\gexec
        ALTER DATABASE "${db}" OWNER TO ${service.user};
        GRANT ALL PRIVILEGES ON DATABASE "${db}" TO admin;
      '') service.dbs
    )}
  '';
in
{
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

    containerConfig = {
      volumes = {
        postgres-data = "/opt/postgres/data";
        pgadmin-data = "/opt/postgres/pgadmin";
      };
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../secrets/${name}.age;
        mode = "444";
      };
    in
    {
      postgres-pw = mkSecret "s_postgres-pw";
      pgadmin-pw = mkSecret "s_pgadmin-pw";
    };

  home.file."containers/postgres/init-all-db.sql".text = ''
    -- Prevent script from crashing if a command fails
    \set ON_ERROR_STOP off

    ${builtins.concatStringsSep "\n" (map mkSql services)}
  '';

  # [access postgres database]
  # podman exec -it postgres psql -U admin -d app_db

  # [run init script]
  # cat ~/containers/postgres/init-all-db.sql | podman exec -i postgres psql -U admin -d postgres

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.postgres-net = {
        networkConfig = {
          internal = false;
        };
      };

      volumes.postgres-data.volumeConfig = {
        type = "bind";
        device = config.myServices.postgres.containerConfig.volumes.postgres-data;
      };

      volumes.pgadmin-data.volumeConfig = {
        type = "bind";
        device = config.myServices.postgres.containerConfig.volumes.pgadmin-data;
      };

      containers.postgres = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/library/postgres:${postgresVersion}";
          name = "postgres";
          networks = [ "postgres-net" ];

          environments = {
            TZ = "Europe/Berlin";

            POSTGRES_USER = "admin";
            POSTGRES_PASSWORD_FILE = "/run/secrets/POSTGRES_PASSWORD";

            POSTGRES_DB = "app_db";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # secrets
            "${config.age.secrets.postgres-pw.path}:/run/secrets/POSTGRES_PASSWORD:ro"

            # volumes
            "${volumes.postgres-data.ref}:/var/lib/postgresql:U"

            # startup scripts
            "${config.home.homeDirectory}/containers/postgres/init-all-db.sql:/docker-entrypoint-initdb.d/init-all-db.sql:ro,U"
          ];

          publishPorts = [
            "${toString ports.postgres}:5432/tcp"
          ];
        };
      };

      # https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html
      containers.pgadmin = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/dpage/pgadmin4:${pgadminVersion}";
          name = "pgadmin";
          networks = [ "postgres-net" ];

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
