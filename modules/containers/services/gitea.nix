/*
  modules/containers/services/qbittorrent.nix

  part of der-home-server
  created 2026-04-12
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

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.gitea.com/gitea:${giteaVersion}";
          name = "gitea";
          userns = "keep-id:uid=10000,gid=10000";

          environments = {
            USER_UID = "10000";
            USER_GID = "10000";

            GITEA__database__DB_TYPE = "postgres";
            GITEA__database__HOST = "host.containers.internal:5432";
            GITEA__database__NAME = "gitea";
            GITEA__database__USER = "gitea";
            GITEA__database__PASSWD = "gitea";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

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
