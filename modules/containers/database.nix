/*
  modules/containers/database.nix

  part of der-home-server
  created 2026-04-14
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
in
{
  age.secrets = {
    postgres-pw = {
      file = ../../secrets/postgres-pw.age;
    };

    pgadmin-pw = {
      file = ../../secrets/pgadmin-pw.age;
    };
  };

  home.file."containers/postgres/authelia-init.sql" = {
    text = ''
      CREATE DATABASE authelia;
      ALTER DATABASE authelia OWNER TO admin;
      GRANT ALL PRIVILEGES ON DATABASE authelia TO admin;
    '';
  };

  home.file."containers/postgres/lldap-init.sql" = {
    text = ''
      CREATE USER lldap;
      ALTER USER lldap WITH PASSWORD 'lldap';

      CREATE DATABASE lldap;
      ALTER DATABASE lldap OWNER TO lldap;

      GRANT ALL PRIVILEGES ON DATABASE lldap TO admin;
    '';
  };

  home.file."containers/postgres/gitea-init.sql" = {
    text = ''
      CREATE USER gitea;
      ALTER USER gitea WITH PASSWORD 'gitea';

      CREATE DATABASE gitea;
      ALTER DATABASE gitea OWNER TO gitea;

      GRANT ALL PRIVILEGES ON DATABASE gitea TO admin;
    '';
  };

  home.file."containers/postgres/ebk-init.sql" = {
    text = ''
      CREATE USER ebk;
      ALTER USER ebk WITH PASSWORD 'ebk';

      CREATE DATABASE ebk;
      ALTER DATABASE ebk OWNER TO ebk;

      GRANT ALL PRIVILEGES ON DATABASE ebk TO admin;
    '';
  };

  home.file."containers/postgres/lidarr-init.sql" = {
    text = ''
      CREATE USER lidarr;
      ALTER USER lidarr WITH PASSWORD 'lidarr';

      CREATE DATABASE "lidarr-main";
      ALTER DATABASE "lidarr-main" OWNER TO lidarr;

      CREATE DATABASE "lidarr-log";
      ALTER DATABASE "lidarr-log" OWNER TO lidarr;

      GRANT ALL PRIVILEGES ON DATABASE "lidarr-main" TO admin;
      GRANT ALL PRIVILEGES ON DATABASE "lidarr-log" TO admin;
    '';
  };

  # access postgres database
  # podman exec -it postgres psql -U admin -d app_db

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
        device = "/opt/postgres/data";
      };

      volumes.pgadmin-data.volumeConfig = {
        type = "bind";
        device = "/opt/postgres/pgadmin";
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
          user = "0:0";
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
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"
            
            # secrets
            "${config.age.secrets.postgres-pw.path}:/run/secrets/POSTGRES_PASSWORD:ro"

            # volumes
            "${volumes.postgres-data.ref}:/var/lib/postgresql"

            # startup scripts
            "${config.home.homeDirectory}/containers/postgres/authelia-init.sql:/docker-entrypoint-initdb.d/authelia-init.sql:ro"
            "${config.home.homeDirectory}/containers/postgres/lldap-init.sql:/docker-entrypoint-initdb.d/lldap-init.sql:ro"
            "${config.home.homeDirectory}/containers/postgres/gitea-init.sql:/docker-entrypoint-initdb.d/gitea-init.sql:ro"
            "${config.home.homeDirectory}/containers/postgres/ebk-init.sql:/docker-entrypoint-initdb.d/ebk-init.sql:ro"
            "${config.home.homeDirectory}/containers/postgres/lidarr-init.sql:/docker-entrypoint-initdb.d/lidarr-init.sql:ro"
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
          user = "0:0";
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
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            # secrets
            "${config.age.secrets.pgadmin-pw.path}:/run/secrets/PGADMIN_PASSWORD:ro"

            # volumes
            "${volumes.pgadmin-data.ref}:/var/lib/pgadmin"
          ];

          publishPorts = [
            "${toString ports.pgadmin}:80/tcp"
          ];
        };
      };
    };
}
