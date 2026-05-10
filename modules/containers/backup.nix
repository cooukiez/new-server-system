/*
  modules/containers/backup.nix

  part of der-home-server
  created 2026-04-20
*/

{
  config,
  pkgs,
  ports,
  ...
}:
let
  borgUIVersion = "latest";
  redisVersion = "alpine";
in
{
  myServices.borg-backup = {
    serviceConfig = {
      name = "Borg-Backup";
      description = "Backup Management System";
      serviceType = "Services";

      subdomain = "bak";
      port = ports.borg;

      policy = "bypass";

      icon = "https://avatars.githubusercontent.com/u/12418060?s=48&v=4";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.borg-net = {
        networkConfig = {
          internal = false;
        };
      };

      # source
      volumes.data-documents.volumeConfig = {
        type = "bind";
        device = "/data/documents";
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
          image = "docker.io/library/redis:${redisVersion}";
          name = "borg-redis";
          networks = [ "borg-net" ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
      };

      containers.borg = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-borg" ''
              ${pkgs.coreutils}/bin/mkdir -p "/opt/borg/data"
              ${pkgs.coreutils}/bin/mkdir -p "/opt/borg/cache"
            ''}"
          ];
        };

        containerConfig = {
          image = "docker.io/ainullcode/borg-ui:${borgUIVersion}";
          name = "borg";
          networks = [ "borg-net" ];

          environments = {
            TZ = "Europe/Berlin";

            PUID = "0";
            PGID = "0";

            REDIS_HOST = "borg-redis";
            REDIS_PORT = "6379";

            # configure for authelia
            # DISABLE_AUTHENTICATION = "true";
            # PROXY_AUTH_HEADER = "X-Remote-User";
          };

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
