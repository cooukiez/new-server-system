/*
  modules/containers/services/vnstat.nix

  part of der-home-server
  created 2026-04-16
*/

{
  config,
  ports,
  ...
}:
let
  atuinVersion = "latest";
in
{
  myServices.atuin = {
    containerConfig = {
      volumes = {
        atuin-config = "/opt/atuin/config";
      };
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.atuin-config.volumeConfig = {
        type = "bind";
        device = config.myServices.atuin.containerConfig.volumes.atuin-config;
      };

      containers.atuin = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/atuinsh/atuin:${atuinVersion}";
          name = "atuin";

          environments = {
            TZ = "Europe/Berlin";

            ATUIN_HOST = "0.0.0.0";
            ATUIN_PORT = "8888";

            ATUIN_OPEN_REGISTRATION  = "true";
            ATUIN_DB_URI = "postgres://atuin:atuin@host.containers.internal:${toString ports.postgres}/atuin";

            RUST_LOG = "info,atuin_server=debug";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.atuin-config.ref}:/config:ro"
          ];

          publishPorts = [
            "${toString ports.atuin}:8888/tcp"
          ];
        };
      };
    };
}
