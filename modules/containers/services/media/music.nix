/*
  modules/containers/services/immich.nix

  part of der-home-server
  created 2026-04-10
*/

{
  config,
  ports,
  musicPath,
  ...
}:
let
  lidarrVersion = "latest";
in
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.lidarr-data.volumeConfig = {
        type = "bind";
        device = "/opt/lidarr/data";
      };

      containers.lidarr = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "lscr.io/linuxserver/lidarr:${lidarrVersion}";
          name = "lidarr";
          networks = [ "media-net" ];
          
          environments = {
            PUID = "10000";
            PGID = "10000";
            TZ = "Europe/Berlin";
          };

          volumes = [
            "${volumes.lidarr-data.ref}:/config"
            
            # media volumes
            "${volumes.media-download.ref}:/download"
            "${volumes.media-music.ref}:/music"
          ];

          publishPorts = [
            "${toString ports.lidarr}:8686/tcp"
          ];
        };
      };
    };
}
