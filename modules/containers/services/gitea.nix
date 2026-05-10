/*
  modules/containers/services/gitea.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  pkgs,
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
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.gitea-data.volumeConfig = {
        type = "bind";
        device = "/opt/gitea/data";
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

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-start" ''
              ${pkgs.coreutils}/bin/mkdir -p "/opt/gitea/data"
            ''}"
          ];
        };

        containerConfig = {
          image = "docker.gitea.com/gitea:${giteaVersion}";
          name = "gitea";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";

            GITEA__database__DB_TYPE = "postgres";
            GITEA__database__HOST = "host.containers.internal:${toString ports.postgres}";
            GITEA__database__NAME = "gitea";
            GITEA__database__USER = "gitea";

            # todo: private db password
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
