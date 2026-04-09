{
  config,
  staticIP,
  ports,
  ...
}:
let
  mediaPath = "/media/photos";
  dbPath = "/opt/immich/db";
  mlCachePath = "/opt/immich/ml-cache";

  immichVersion = "release";
  immichDbVersion = "14-vectorchord0.5.3";
  redisVersion = "alpine";
in
{
  age.secrets = {
    immich-db-pw = {
      file = ../../../secrets/postgres-pw.age;
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.immich-net = {
        networkConfig = {
          internal = false;
        };
      };

      volumes.immich-media.volumeConfig = {
        type = "bind";
        device = mediaPath;
      };

      volumes.immich-db.volumeConfig = {
        type = "bind";
        device = dbPath;
      };

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
          networks = [ "immich-net" ];

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
          networks = [ "immich-net" ];
        };
      };

      # immich database
      containers.immich-postgres = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/immich-app/postgres:${immichDbVersion}";
          name = "immich-postgres";
          networks = [ "immich-net" ];

          environments = {
            POSTGRES_USER = "admin";
            POSTGRES_PASSWORD_FILE = "/run/secrets/IMMICH_DB_PW";

            POSTGRES_DB = "immich";
            POSTGRES_INITDB_ARGS = "--data-checksums";
          };

          volumes = [
            "${volumes.immich-db.ref}:/var/lib/postgresql/data"
            "${config.age.secrets.immich-db-pw.path}:/run/secrets/IMMICH_DB_PW"
          ];
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
          networks = [ "immich-net" ];
          
          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            DB_DATABASE_NAME = "immich";
            DB_HOSTNAME = "immich-postgres";
            DB_PORT = "5432";

            DB_USERNAME = "admin";
            DB_PASSWORD_FILE = "/run/secrets/IMMICH_DB_PW";

            IMMICH_MACHINE_LEARNING_URL = "http://immich-ml:3003";
            REDIS_HOSTNAME = "immich-redis";

            NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/home.lan.crt";
          };

          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${../../../home.lan.crt}:/etc/ssl/certs/home.lan.crt:ro"

            # secrets
            "${config.age.secrets.immich-db-pw.path}:/run/secrets/IMMICH_DB_PW"

            # volumes
            "${volumes.immich-media.ref}:/data"
          ];

          devices = [
            "/dev/dri/renderD128"
            "/dev/dri/card0"
          ];

          publishPorts = [
            "${toString ports.immich}:2283/tcp"
          ];
        };
      };
    };
}
