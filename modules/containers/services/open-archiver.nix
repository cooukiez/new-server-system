{
  config,
  ports,
  envSecretsPrefix,
  ...
}:
let
  meiliVersion = "latest";
  redisVersion = "alpine";
  openArchiverVersion = "latest";
in
{
  myServices.open-archiver = {
    serviceConfig = {
      description = "Mail Archiving System";
      serviceType = "Apps";

      subdomain = "archiver";
      port = ports.open-archiver;

      policy = "bypass";

      icon = "open-archiver";
    };

    containerConfig = {
      volumes = {
        open-archiver-meili = "/opt/open-archiver/meili";
        open-archiver-redis = "/opt/open-archiver/redis";
        open-archiver-data = "/opt/open-archiver/data";
      };
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
        mode = "444";
      };
    in
    {
      archiver-meily-key = mkSecret "archiver/e_meili-key";
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

      volumes.open-archiver-meili.volumeConfig = {
        type = "bind";
        device = config.myServices.open-archiver.containerConfig.volumes.open-archiver-meili;
      };

      volumes.open-archiver-redis.volumeConfig = {
        type = "bind";
        device = config.myServices.open-archiver.containerConfig.volumes.open-archiver-redis;
      };

      volumes.open-archiver-data.volumeConfig = {
        type = "bind";
        device = config.myServices.open-archiver.containerConfig.volumes.open-archiver-data;
      };

      containers.open-archiver-meili = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/getmeili/meilisearch:${meiliVersion}";
          name = "open-archiver-meili";
          networks = [ "open-archiver-net" ];

          environments = {
            MEILI_NO_ANALYTICS = "true";
          };

          environmentFiles = [
            "secrets/archiver/e_meili-key"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            "${volumes.open-archiver-meili.ref}:/meili_data"
          ];
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

          exec = [
            "valkey-server"
            "--requirepass"
            "archiver"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            "${volumes.open-archiver-redis.ref}:/data"
          ];
        };
      };

      containers.open-archiver = {
        autoStart = true;

        unitConfig = {
          Requires = [
            "postgres.service"
            "open-archiver-meili.service"
            "open-archiver-redis.service"
          ];
          After = [
            "postgres.service"
            "open-archiver-meili.service"
            "open-archiver-redis.service"
          ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/logiclabshq/open-archiver:${openArchiverVersion}";
          name = "open-archiver";
          networks = [ "open-archiver-net" ];

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            NODE_ENV = "production";

            # backend configuration
            PORT_BACKEND = "4000";

            NEXT_PUBLIC_API_URL = "http://127.0.0.1:4000";
            API_URL = "http://127.0.0.1:4000";

            PROTOCOL_HEADER = "x-forwarded-proto";
            HOST_HEADER = "x-forwarded-host";

            # frontend
            PORT_FRONTEND = "3000";

            # connections
            DATABASE_URL = "postgresql://archiver:archiver@host.containers.internal:${toString ports.postgres}/open-archiver";
            POSTGRES_DB = "open-archiver";
            POSTGRES_USER = "archiver";
            POSTGRES_PASSWORD = "archiver";

            REDIS_HOST = "open-archiver-redis";
            REDIS_PORT = "6379";
            REDIS_PASSWORD = "archiver";

            MEILI_HOST = "http://open-archiver-meili:7700";
            MEILI_INDEXING_BATCH = "500";

            # storage
            STORAGE_TYPE = "local";
            STORAGE_LOCAL_ROOT_PATH = "/data";

            # secrets
            JWT_EXPIRES_IN = "1y";
          };

          environmentFiles = [
            "secrets/archiver/e_meili-key"
            "secrets/archiver/e_encrypt-key"
            "secrets/archiver/e_jwt-secret"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/ca.crt:/usr/local/share/ca-certificates/ca.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.open-archiver-data.ref}:/data"
          ];

          publishPorts = [
            "${toString ports.open-archiver}:3000/tcp"
          ];
        };
      };
    };
}
