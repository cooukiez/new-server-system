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
  qBittorrentVersion = "latest";
in
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.qbittorrent-config.volumeConfig = {
        type = "bind";
        device = "/opt/qbittorrent/data";
      };

      volumes.qbittorrent-download.volumeConfig = {
        type = "bind";
        device = "/media/download/qbittorrent";
      };

      containers.qbittorrent = {
        autoStart = true;
        
        unitConfig.After = [ "gluetun.service" ];
        unitConfig.Requires = [ "gluetun.service" ];

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "lscr.io/linuxserver/qbittorrent:${qBittorrentVersion}";
          name = "qbittorrent";
          
          # networking through gluetun
          networks = [ "container:gluetun" ];

          environments = {
            PUID = "10000";
            PGID = "10000";

            TZ = "Europe/Berlin";

            WEBUI_PORT = "8080";
            TORRENTING_PORT = "6881";
          };

          volumes = [
            "${volumes.qbittorrent-config.ref}:/config"
            "${volumes.qbittorrent-download.ref}:/download"
          ];
        };
      };
    };
}