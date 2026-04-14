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
{
  age.secrets = {
    postgres-pw = {
      file = ../../secrets/postgres-pw.age;
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

  home.file."containers/postgres/papra-init.sql" = {
    text = ''
      CREATE USER papra;
      ALTER USER papra WITH PASSWORD 'papra';

      CREATE DATABASE papra;
      ALTER DATABASE papra OWNER TO papra;

      GRANT ALL PRIVILEGES ON DATABASE papra TO admin;
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

  # podman exec -it postgres psql -U admin -d app_db

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.postgres-data.volumeConfig = {
        type = "bind";
        device = "/opt/postgres/data";
      };

      containers.postgres = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/library/postgres:alpine";
          name = "postgres";

          environments = {
            POSTGRES_USER = "admin";
            POSTGRES_PASSWORD_FILE = "/run/secrets/POSTGRES_PASSWORD";

            POSTGRES_DB = "app_db";
          };

          volumes = [
            "${config.age.secrets.postgres-pw.path}:/run/secrets/POSTGRES_PASSWORD:ro"
            "${volumes.postgres-data.ref}:/var/lib/postgresql"

            "${config.home.homeDirectory}/containers/postgres/authelia-init.sql:/docker-entrypoint-initdb.d/authelia-init.sql:ro"
            "${config.home.homeDirectory}/containers/postgres/lldap-init.sql:/docker-entrypoint-initdb.d/lldap-init.sql:ro"
            "${config.home.homeDirectory}/containers/postgres/gitea-init.sql:/docker-entrypoint-initdb.d/gitea-init.sql:ro"
            "${config.home.homeDirectory}/containers/postgres/papra-init.sql:/docker-entrypoint-initdb.d/papra-init.sql:ro"
            "${config.home.homeDirectory}/containers/postgres/lidarr-init.sql:/docker-entrypoint-initdb.d/lidarr-init.sql:ro"
          ];

          publishPorts = [
            "${toString ports.postgres}:5432/tcp"
          ];
        };
      };
    };
}
