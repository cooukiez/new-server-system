/*
modules/containers/services/outline.nix

part of server system
created 2026-05-13 by ludw
*/
{
  config,
  pkgs,
  images,
  ports,
  mkEnv,
  ...
}: let
  createEnv = mkEnv {
    path = "containers/outline/env";
    vars = {
      URL = config.myServices.outline.serviceConfig.href;
      PORT = "3000";

      WEB_CONCURRENCY = "1";

      SECRET_KEY = "@PLACEHOLDER_SECRET_KEY@";
      UTILS_SECRET = "@PLACEHOLDER_UTILS_SECRET@";

      DEFAULT_LANGUAGE = "en_US";

      DATABASE_URL = let
        name = "outline";
        user = "admin";
        pass = "@PLACEHOLDER_DB_PASS@";

        host = "outline-postgres";
        port = "5432";
      in "postgres://${user}:${pass}@${host}:${port}/${name}?sslmode=disable";

      REDIS_URL = "outline-redis:6379";

      NODE_EXTRA_CA_CERTS = "/certs/ca.crt";

      OIDC_CLIENT_ID = "outline";
      OIDC_CLIENT_SECRET = "@PLACEHOLDER_CLIENT_KEY@";
      OIDC_AUTH_URI = "https://auth.home.lan/api/oidc/authorization";
      OIDC_TOKEN_URI = "https://auth.home.lan/api/oidc/token";
      OIDC_USERINFO_URI = "https://auth.home.lan/api/oidc/userinfo";
      OIDC_USERNAME_CLAIM = "preferred_username";
      OIDC_DISPLAY_NAME = "Authelia";
      OIDC_SCOPES = "openid offline_access profile email";

      FILE_STORAGE = "local";
      FILE_STORAGE_LOCAL_ROOT_DIR = "/data";
      FILE_STORAGE_UPLOAD_MAX_SIZE = "26214400";
      FILE_STORAGE_IMPORT_MAX_SIZE = "";
      FILE_STORAGE_WORKSPACE_IMPORT_MAX_SIZE = "";

      RATE_LIMITER_ENABLED = "false";
      RATE_LIMITER_DURATION_WINDOW = "60";
      RATE_LIMITER_REQUESTS = "1000";

      LOG_LEVEL = "info";
    };

    secrets = {
      PLACEHOLDER_CLIENT_KEY = config.age.secrets.outline-client-key.path;
      PLACEHOLDER_DB_PASS = config.age.secrets.outline-db-pass.path;
      PLACEHOLDER_SECRET_KEY = config.age.secrets.outline-secret-key.path;
      PLACEHOLDER_UTILS_SECRET = config.age.secrets.outline-utils-secret.path;
    };
  };
in {
  myServices.outline = {
    serviceConfig = {
      name = "Outline";
      description = "Universal Knowledge Database";
      serviceType = "Apps";

      subdomain = "outline";
      port = ports.outline;

      policy = "bypass";

      icon = "outline";
    };
  };

  age.secrets = let
    mkSecret = name: {
      file = ../../../secrets/containers/outline/${name}.age;
    };
  in {
    outline-client-key = mkSecret "s_auth-client";
    outline-db-pass = mkSecret "s_db-pass";
    outline-secret-key = mkSecret "s_secret-key";
    outline-utils-secret = mkSecret "s_utils-secret";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    networks.outline-net = {
      networkConfig = {
        internal = false;
      };
    };

    volumes.outline-db.volumeConfig = {
      type = "bind";
      device = "/opt/outline/db";
    };

    volumes.outline-data.volumeConfig = {
      type = "bind";
      device = "/opt/outline/data";
    };

    containers.outline-redis = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.redis}";
        name = "outline-redis";
        networks = [networks.outline-net.ref];

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
    };

    containers.outline-postgres = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.postgres}";
        name = "outline-postgres";
        networks = [networks.outline-net.ref networks.postgres-net.ref];

        environments = {
          POSTGRES_USER = "admin";
          POSTGRES_PASSWORD_FILE = "/run/secrets/OUTLINE_DB_PASS";

          POSTGRES_DB = "outline";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          "${volumes.outline-db.ref}:/var/lib/postgresql:U"
          "${config.age.secrets.outline-db-pass.path}:/run/secrets/OUTLINE_DB_PASS:ro"
        ];
      };
    };

    containers.outline = {
      autoStart = true;

      unitConfig = {
        Requires = [
          "outline-redis.service"
          "outline-postgres.service"
        ];

        After = [
          "outline-redis.service"
          "outline-postgres.service"
        ];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-outline" ''
            ${createEnv}
          ''}"
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.outline}";
        name = "outline";
        networks = [networks.outline-net.ref];

        addHosts = [
          "auth.home.lan:host-gateway"
        ];

        environments = {
          TZ = "Europe/Berlin";
        };

        environmentFiles = [
          "env/containers/outline/env"
        ];

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          "${volumes.outline-data.ref}:/data:U"
        ];

        publishPorts = [
          "${toString ports.outline}:3000/tcp"
        ];
      };
    };
  };
}
