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
  cronJobsDir = "${config.home.homeDirectory}/.crontab/jobs";
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

  systemd.user.services.crontab-executor = {
    Unit = {
      Description = "User-level Cron Executor for Crontab Container";
      After = [ "network.target" ];
    };

    Service = {
      ExecStart = "${pkgs.cronie}/bin/crond -n -p -c ${cronJobsDir}";
      
      Restart = "always";
      RestartSec = "10";

      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cronJobsDir}";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.crontab-jobs.volumeConfig = {
        type = "bind";
        device = cronJobsDir;
      };

      volumes.crontab-data.volumeConfig = {
        type = "bind";
        device = config.myServices.crontab.containerConfig.volumes.crontab-data;
      };

      containers.crontab = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/alseambusher/crontab-ui:${crontabVersion}";
          name = "crontab";
          user = "0:0";

          environments = {
            TZ = "Europe/Berlin";
            PORT = "8000";

            CRON_DB_PATH = "/crontab-ui";
            CRON_PATH = "/etc/crontabs";

            ENABLE_AUTOSAVE = "true";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
            
            "${volumes.crontab-data.ref}:/crontab-ui:U"
            "${volumes.crontab-jobs.ref}:/etc/crontabs:U"
          ];

          publishPorts = [
            "${toString ports.crontab}:8000/tcp"
          ];
        };
      };
    };
}