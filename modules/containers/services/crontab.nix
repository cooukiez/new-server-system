/*
  modules/containers/services/crontab.nix

  part of der-home-server
  created 2026-04-21
*/

{
  config,
  pkgs,
  images,
  ports,
  ...
}:
{
  myServices.crontab = {
    serviceConfig = {
      name = "Crontab UI";
      description = "Web-based Crontab Manager";
      serviceType = "Services";

      subdomain = "crontab";
      port = ports.crontab;

      policy = "two_factor";
      group = "admins";

      icon = "https://avatars.githubusercontent.com/u/1242542?s=48&v=4";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.crontab-data.volumeConfig = {
        type = "bind";
        device = "/opt/crontab/data";
      };

      containers.crontab = {
        autoStart = true;

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.crontab}";
          name = "crontab";
          user = "0:0";

          environments = {
            TZ = "Europe/Berlin";
            PORT = "8000";

            CRON_DB_PATH = "/data";
            CRON_PATH = "/etc/crontabs";

            ENABLE_AUTOSAVE = "true";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            "${volumes.crontab-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.crontab}:8000/tcp"
          ];
        };
      };
    };
}
