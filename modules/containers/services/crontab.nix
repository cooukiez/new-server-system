/*
  modules/containers/services/crontab.nix

  part of der-home-server
  created 2026-04-21
*/

{
  config,
  pkgs,
  ports,
  ...
}:
let
  gitRepo = "https://github.com/alseambusher/crontab-ui.git";
  buildDir = "${config.home.homeDirectory}/containers/crontab/build";
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

      builds.crontab-image = {
        serviceConfig = {
          ExecStartPre = [
            "-${pkgs.coreutils}/bin/rm -rf ${buildDir}"
            "${pkgs.git}/bin/git clone ${gitRepo} ${buildDir}"
            "${pkgs.coreutils}/bin/cp ${../builds/crontab.Dockerfile} ${buildDir}/crontab.Dockerfile"
            "${pkgs.coreutils}/bin/chmod -R u+rw ${buildDir}"
          ];
        };

        buildConfig = {
          file = "${pkgs.writeText "crontab.Dockerfile" (builtins.readFile ../builds/crontab.Dockerfile)}";

          workdir = "${buildDir}";
          tag = "localhost/crontab:internal";
        };
      };

      containers.crontab = {
        autoStart = true;

        unitConfig = {
          Requires = [ "crontab-image-build.service" ];
          After = [ "crontab-image-build.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "localhost/crontab:internal";
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
          ];

          publishPorts = [
            "${toString ports.crontab}:8000/tcp"
          ];
        };
      };
    };
}
