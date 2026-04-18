/*
  modules/containers/services/immich.nix

  part of der-home-server
  created 2026-04-12
*/

{
  config,
  ports,
  ...
}:
let
  photosPath = "/media/photos";

  dbPath = "/opt/immich/db";
  mlCachePath = "/opt/immich/ml-cache";

  redisVersion = "alpine";
  immichDbVersion = "14-vectorchord0.5.3";
  immichVersion = "release";
in
{
  age.secrets = {
    immich-db-pw.file = ../../../secrets/s_postgres-pw.age;
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
        device = photosPath;
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
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            "${volumes.immich-ml-cache.ref}:/cache:U"
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

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
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
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            "${volumes.immich-db.ref}:/var/lib/postgresql/data:U"
            "${config.age.secrets.immich-db-pw.path}:/run/secrets/IMMICH_DB_PW:ro"
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
            TZ = "Europe/Berlin";

            DB_DATABASE_NAME = "immich";
            DB_HOSTNAME = "immich-postgres";
            DB_PORT = "5432";

            DB_USERNAME = "admin";
            DB_PASSWORD_FILE = "/run/secrets/IMMICH_DB_PW";

            IMMICH_MACHINE_LEARNING_URL = "http://immich-ml:3003";
            REDIS_HOSTNAME = "immich-redis";

            NODE_EXTRA_CA_CERTS = "/certs/ca.crt";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/ca.crt:/usr/local/share/ca-certificates/ca.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # secrets
            "${config.age.secrets.immich-db-pw.path}:/run/secrets/IMMICH_DB_PW:ro"

            # volumes
            "${volumes.immich-media.ref}:/data:U"
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
