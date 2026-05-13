/*
modules/containers/backup.nix

part of server system
created 2026-04-20
*/
{
  config,
  pkgs,
  images,
  ports,
  mkEnv,
  documentsPath,
  ...
}: let
  createEnv = mkEnv {
    path = "containers/borg/env";
    vars = {
      ENVIRONMENT = "production";
      PORT = "8081";

      PUID = "0";
      PGID = "0";

      SECRET_KEY = "@PLACEHOLDER_SECRET_KEY@";
      INITIAL_ADMIN_PASSWORD = "@PLACEHOLDER_ADMIN_PASS@";

      REDIS_HOST = "borg-redis";
      REDIS_PORT = "6379";

      DATA_DIR = "/data";
      LOCAL_MOUNT_POINTS = "/local";

      # authelia proxy auth
      DISABLE_AUTHENTICATION = "true";
      PROXY_AUTH_HEADER = "X-Remote-User";
      PROXY_AUTH_ROLE_HEADER = "X-Remote-Role";

      LOG_LEVEL = "info";
    };

    secrets = {
      PLACEHOLDER_ADMIN_PASS = config.age.secrets.borg-admin-pass.path;
      PLACEHOLDER_SECRET_KEY = config.age.secrets.borg-secret-key.path;
    };
  };
in {
  myServices.borg-backup = {
    serviceConfig = {
      name = "Borg-Backup";
      description = "Backup Management System";
      serviceType = "Services";

      subdomain = "bak";
      port = ports.borg;

      disableProxy = true;
      policy = "two_factor";
      group = "admins";

      icon = "https://avatars.githubusercontent.com/u/12418060?s=48&v=4";
    };
  };

  age.secrets = let
    mkSecret = name: {
      file = ../../secrets/containers/borg/${name}.age;
    };
  in {
    borg-admin-pass = mkSecret "s_admin-pass";
    borg-secret-key = mkSecret "s_secret-key";
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks pods;
  in {
    networks.borg-net = {
      networkConfig = {
        internal = false;
      };
    };

    # source
    volumes.data-documents.volumeConfig = {
      type = "bind";
      device = documentsPath;
    };

    volumes.data-opt.volumeConfig = {
      type = "bind";
      device = "/opt";
    };

    # backup
    volumes.external-documents.volumeConfig = {
      type = "bind";
      device = "/bak/documents";
    };

    volumes.external-git.volumeConfig = {
      type = "bind";
      device = "/bak/git";
    };

    volumes.external-opt.volumeConfig = {
      type = "bind";
      device = "/bak/opt";
    };

    # borg volumes
    volumes.borg-data.volumeConfig = {
      type = "bind";
      device = "/opt/borg/data";
    };

    volumes.borg-cache.volumeConfig = {
      type = "bind";
      device = "/opt/borg/cache";
    };

    containers.borg-redis = {
      autoStart = true;
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.redis}";
        name = "borg-redis";
        networks = ["borg-net"];

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
    };

    containers.borg = {
      autoStart = true;

      unitConfig = {
        Requires = ["borg-redis.service"];
        After = ["borg-redis.service"];
      };

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";

        ExecStartPre = [
          "+${pkgs.writeShellScript "pre-borg" ''
            ${createEnv}
          ''}"
        ];
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.borg-ui}";
        name = "borg";
        networks = ["borg-net"];

        environments = {
          TZ = "Europe/Berlin";
        };

        environmentFiles = [
          "env/containers/borg/env"
        ];

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          "${volumes.data-documents.ref}:/local/documents:ro"
          "${volumes.data-opt.ref}:/local/opt:ro"

          "${volumes.external-documents.ref}:/external/documents:U"
          "${volumes.external-git.ref}:/external/git:U"
          "${volumes.external-opt.ref}:/external/opt:U"

          "${volumes.borg-data.ref}:/data:U"
          "${volumes.borg-cache.ref}:/home/borg/.cache/borg:U"
        ];

        publishPorts = [
          "${toString ports.borg}:8081/tcp"
        ];
      };
    };
  };
}
