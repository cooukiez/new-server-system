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

        };

        containerConfig = {
          image = "docker.gitea.com/gitea:${giteaVersion}";
          name = "gitea";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          exec = "/bin/sh -c 'update-ca-certificates && /usr/bin/entrypoint /usr/bin/s6-svscan /etc/s6'";

          environments = {
            USER_UID = "1000";
            USER_GID = "1000";

            GITEA__database__DB_TYPE = "postgres";
            GITEA__database__HOST = "host.containers.internal:5432";
            GITEA__database__NAME = "gitea";
            GITEA__database__USER = "gitea";
            GITEA__database__PASSWD = "gitea";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/cert/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "${volumes.caddy-certs.ref}:/certs"

            # volumes
            "${volumes.gitea-data.ref}:/data"
          ];

          publishPorts = [
            "${toString ports.giteaHttp}:3000/tcp"
            "${toString ports.gitea}:22/tcp"
          ];
        };
      };
    };
}
