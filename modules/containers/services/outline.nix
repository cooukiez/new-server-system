/*
  modules/containers/services/outline.nix

  part of server system
  created 2026-04-20
*/

{
  config,
  pkgs,
  images,
  ports,
  ...
}:
{
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

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.outline-net = {
        networkConfig = {
          internal = false;
        };
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
          networks = [ "outline-net" ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
      };

      containers.outline = {
        autoStart = true;

        unitConfig = {
          Requires = [
            "postgres.service"
            "outline-redis.service"
          ];

          After = [
            "postgres.service"
            "outline-redis.service"
          ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.outline}";
          name = "outline";
          networks = [ "outline-net" ];

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.outline-data.ref}:/var/lib/outline/data:U"
          ];

          publishPorts = [
            "${toString ports.outline}:3000/tcp"
          ];
        };
      };
    };
}
