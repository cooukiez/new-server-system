/*
  modules/containers/database.nix

  part of der-home-server
  created 2026-04-08
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
  };CREATE DATABASE lidarr-main;

  home.file."containers/postgres/authelia-init.sql" = {
    text = ''
      CREATE USER authelia;
      ALTER USER authelia WITH PASSWORD 'authelia';

      CREATE DATABASE authelia;

      GRANT ALL PRIVILEGES ON DATABASE authelia TO admin;
      GRANT ALL PRIVILEGES ON DATABASE authelia TO authelia;
    '';
  };

  home.file."containers/postgres/lldap-init.sql" = {
    text = ''
      CREATE USER lldap;
      ALTER USER lldap WITH PASSWORD 'lldap';

      CREATE DATABASE lldap;

      GRANT ALL PRIVILEGES ON DATABASE lldap TO admin;
      GRANT ALL PRIVILEGES ON DATABASE lldap TO lldap;
    '';
  };

  home.file."containers/postgres/gitea-init.sql" = {
    text = ''
      CREATE USER gitea;
      ALTER USER gitea WITH PASSWORD 'gitea';

      CREATE DATABASE gitea;

      GRANT ALL PRIVILEGES ON DATABASE gitea TO admin;
      GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;
    '';
  };

  home.file."containers/postgres/lidarr-init.sql" = {
    text = ''
      CREATE USER lidarr;
      ALTER USER lidarr WITH PASSWORD 'lidarr';

      CREATE DATABASE lidarrMain;
      CREATE DATABASE lidarrLog;

      GRANT ALL PRIVILEGES ON DATABASE lidarrMain TO admin;
      GRANT ALL PRIVILEGES ON DATABASE lidarrLog TO admin;

      GRANT ALL PRIVILEGES ON DATABASE lidarrMain TO gitea;
      GRANT ALL PRIVILEGES ON DATABASE lidarrLog TO gitea;
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
            "${config.home.homeDirectory}/containers/postgres/lidarr-init.sql:/docker-entrypoint-initdb.d/lidarr-init.sql:ro"
          ];

          publishPorts = [
            "${toString ports.postgres}:5432/tcp"
          ];
        };
      };
    };
}
