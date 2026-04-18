{
  config,
  ports,
  ...
}:
let
  meiliSearchVersion = "latest";
  redisVersion = "alpine";
  openArchiverVersion = "latest";
in
{

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
      };
    in
    {
      meily-key = mkSecret "archiver/e_meili_key";
      encrypt-key = mkSecret "archiver/e_encrypt-key";
      jwt-secret = mkSecret "archiver/e_jwt-secret";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.open-archiver-net = {
        networkConfig = {
          internal = false;
        };
      };

      volumes.open-archiver-data.volumeConfig = {
        type = "bind";
        device = "/opt/open-archiver/data";
      };

      containers.open-archiver-meili = {
        containerConfig = {
          image = "docker.io/getmeili/meilisearch:${meiliSearchVersion}";
          name = "open-archiver-meili";
          networks = [ "open-archiver-net" ];

          environments = {
            MEILI_NO_ANALYTICS = "true";
          };

          environmentFiles = {
            "secrets/archiver/e_meili_key"
          };
        };
      };

      containers.open-archiver-redis = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/valkey/valkey:${redisVersion}";
          name = "open-archiver-redis";
          networks = [ "open-archiver-net" ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
      };

      containers.open-archiver = {
        autoStart = true;
        containerConfig = {
          image = "docker.io/logiclabshq/open-archiver:${openArchiverVersion}";
          name = "open-archiver";
          networks = [ "open-archiver-net" ];
          
          environments = {
            NODE_ENV = "production";
            PORT_FRONTEND = "3000";

            DATABASE_URL = "postgresql://host.containers.internal:${toString ports.postgres}/open_archiver";
            POSTGRES_DB = "open-archiver";
            POSTGRES_USER = "open-archiver";
            POSTGRES_PASSWORD = "open-archiver";
            
            REDIS_HOST = "valkey";
            REDIS_PORT = "6379";
            REDIS_PASSWORD = "";

            MEILI_HOST = "http://open-archiver-meili:7700";
            MEILI_INDEXING_BATCH = "500";
            
            ENCRYPTION_KEY = encryptionKey;
            JWT_SECRET = jwtSecret;

            STORAGE_TYPE = "local";
            STORAGE_LOCAL_ROOT_PATH = "/data";
          };

          environmentFiles = {
            "secrets/archiver/e_meili_key"
            "secrets/archiver/e_encrypt-key"
            "secrets/archiver/e_jwt-secret"
          };

          volumes = [
            "${volumes.open-archiver-data.ref}:/data"
          ];

          publishPorts = [
            "${toString ports.open-archiver}:3000/tcp"
          ];
        };
      };
    };
}