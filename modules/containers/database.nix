{
  config,
  pkgs,
  ...
}:
{
  age.secrets = {
    postgresql-pw = {
      file = ../../secrets/postgresql-pw.age;
    };
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

          environment = {
            POSTGRES_USER = "admin";
            POSTGRES_PASSWORD_FILE = "/run/secrets/POSTGRESQL_PASSWORD";

            POSTGRES_DB = "app_db";
          };

          volumes = [
            "${config.age.secrets.postgresql-pw.path}:/run/secrets/POSTGRESQL_PASSWORD"
            "${volumes.postgres-data.ref}:/var/lib/postgresql"
          ];

          publishPorts = [
            "5432:5432/tcp"
          ];
        };
      };
    };
}