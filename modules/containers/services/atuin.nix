/*
  modules/containers/services/atuin.nix

  part of der-home-server
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
  myServices.atuin = {
    serviceConfig = {
      name = "Atuin";
      description = "Syncing Shell History";
      serviceType = "Apps";

      subdomain = "atuin";
      port = ports.atuin;

      policy = "bypass";

      icon = "atuin";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.atuin-config.volumeConfig = {
        type = "bind";
        device = "/opt/atuin/config";
      };

      containers.atuin = {
        autoStart = true;

        unitConfig = {
          Requires = [ "postgres.service" ];
          After = [ "postgres.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.atuin}";
          name = "atuin";

          exec = [ "start" ];

          environments = {
            TZ = "Europe/Berlin";

            ATUIN_HOST = "0.0.0.0";
            ATUIN_PORT = "8888";

            ATUIN_OPEN_REGISTRATION = "true";

            # todo: private db password
            ATUIN_DB_URI = "postgres://atuin:atuin@host.containers.internal:${toString ports.postgres}/atuin";

            RUST_LOG = "info,atuin_server=debug";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.atuin-config.ref}:/config:U"
          ];

          publishPorts = [
            "${toString ports.atuin}:8888/tcp"
          ];
        };
      };
    };
}
