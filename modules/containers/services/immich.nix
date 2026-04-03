{
  config,
  ...
}:
let
  mediaPath = "/media/photos";
  dbPath = "/opt/immich/db";
  mlCachePath = "/opt/immich/ml-cache";

  immichVersion = "v1.102.3";
  redisVersion = "alpine";
in
{
  age.secrets = {
    immich-db-pw = {
      file = ../../secrets/postgres-pw.age;
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks volumes;
    in
    {
      volumes.immich-ml-cache.volumeConfig = {
        type = "bind";
        device = mlCachePath;
      };

      # machine learning container
      containers.immich-ml = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
          name = "immich-ml";

          volumes = [
            "${volumes.immich-ml-cache.ref}:/cache"
          ];

          devices = [
            "/dev/dri/renderD128"
          ];
        };
      };

      # immich redis
      containers.immich-redis = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/valkey/valkey:${redisVersion}";
          name = "immich-redis";
        };
      };

      # main immich server
      containers.immich-server = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/immich-app/immich-server:${immichVersion}";
          name = "immich-server";
          
          environments = {
            DB_HOSTNAME = "tcp://host.containers.internal";
            DB_PORT = "5432";

            DB_USERNAME = "admin";
            DB_PASSWORD_FILE = "/run/secrets/IMMICH_DB_PW";

            DB_DATABASE_NAME = "immich";
            
            IMMICH_MACHINE_LEARNING_URL = "tcp://host.containers.internal:3003";
          };

          volumes = [
            "/etc/localtime:/etc/localtime:ro"

            # secrets
            "${config.age.secrets.immich-db-pw.path}:/run/secrets/IMMICH_DB_PW"

            # volumes
            "${mediaPath}:/data"
          ];

          devices = [
            "/dev/dri/renderD128"
            "/dev/dri/card0"
          ];
          
          publishPorts = [
            "2283:2283/tcp"
          ];
        };
      };
    };
}