/*
  modules/containers/services/gitea.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  ports,
  ...
}:
let
  giteaVersion = "1.25.5";
in
{
  myServices.gitea = {
    serviceConfig = {
      name = "Gitea";
      description = "Selfhosted DevOps Platform";
      serviceType = "Apps";

      subdomain = "git";
      port = ports.giteaHttp;

      policy = "bypass";

      icon = "gitea";
    };

    containerConfig = {
      volumes = {
        gitea-data = "/opt/gitea/data";
      };
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.gitea-data.volumeConfig = {
        type = "bind";
        device = config.myServices.gitea.containerConfig.volumes.gitea-data;
      };

      containers.gitea = {
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
          image = "docker.gitea.com/gitea:${giteaVersion}";
          name = "gitea";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          # exec = "/bin/sh -c 'update-ca-certificates && /usr/bin/entrypoint /usr/bin/s6-svscan /etc/s6'";

          environments = {
            TZ = "Europe/Berlin";

            GITEA__database__DB_TYPE = "postgres";
            GITEA__database__HOST = "host.containers.internal:${toString ports.postgres}";
            GITEA__database__NAME = "gitea";
            GITEA__database__USER = "gitea";
            GITEA__database__PASSWD = "gitea";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # volumes
            "${volumes.gitea-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.giteaHttp}:3000/tcp"
            "${toString ports.gitea}:22/tcp"
          ];
        };
      };
    };
}
