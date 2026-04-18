/*
  modules/containers/services/vnstat.nix

  part of der-home-server
  created 2026-04-12
*/

{
  config,
  ports,
  ...
}:
let
  borgUIVersion = "latest";
  redisVersion = "alpine";
in
{
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

      volumes.opt-data.volumeConfig = {
        type = "bind";
        device = "/opt";
      };

      volumes.external-data.volumeConfig = {
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

      # borg redis
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

      # borg server
      containers.borg = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
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
            "/certs/ca.crt:/usr/local/share/ca-certificates/ca.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.opt-data.ref}:/local:ro"
            "${volumes.external-data.ref}:/external:U"

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
