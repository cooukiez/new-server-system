{
  config,
  pkgs,
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
      GRANT ALL PRIVILEGES ON DATABASE authelia TO admin;
    '';
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
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

          environments = {
            POSTGRES_USER = "admin";
            POSTGRES_PASSWORD_FILE = "/run/secrets/POSTGRES_PASSWORD";

            POSTGRES_DB = "app_db";
          };

          volumes = [
            "${config.age.secrets.postgres-pw.path}:/run/secrets/POSTGRES_PASSWORD"
            "${volumes.postgres-data.ref}:/var/lib/postgresql"

            "${config.age.secrets.postgres-pw.path}/containers/postgres/authelia-init.sql:/docker-entrypoint-initdb.d/authelia-init.sql"
          ];

          publishPorts = [
            "5432:5432/tcp"
          ];
        };
      };
    };
}