/*
  modules/containers/services/crontab-ui.nix
  Created 2026-04-21
*/

{
  config,
  pkgs,
  ports,
  ...
}:
let
  crontabVersion = "latest";
in
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

    containerConfig = {
      volumes = {
        crontab-data = "/opt/crontab/data";
      };
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.crontab-data.volumeConfig = {
        type = "bind";
        device = config.myServices.crontab.containerConfig.volumes.crontab-data;
      };

      containers.crontab = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.crontab-ui"
            "${pkgs.coreutils}/bin/touch ${config.home.homeDirectory}/.crontab-ui/squ_crontab"
          ];
        };

        containerConfig = {
          image = "docker.io/alseambusher/crontab-ui:${crontabVersion}";
          name = "crontab";

          environments = {
            TZ = "Europe/Berlin";
            PORT = "8000";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
            
            "${volumes.crontab-data.ref}:/crontab-ui/crontabs"

            "${config.home.homeDirectory}/.crontab-ui:/crontab-ui:U"
          ];

          publishPorts = [
            "${toString ports.crontab}:8000/tcp"
          ];
        };
      };
    };
}