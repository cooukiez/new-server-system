/*
  modules/containers/services/qbittorrent.nix

  part of der-home-server
  created 2026-04-14
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
  myServices.qbittorrent = {
    serviceConfig = {
      description = "Torrent / Magnet Management";
      serviceType = "Restricted";

      subdomain = "torrent";
      port = ports.qbittorrent;

      policy = "bypass";

      icon = "qbittorrent";
    };

    containerConfig = {
      volumes = {
        qbittorrent-config = "/opt/qbittorrent/data";
      };
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.qbittorrent-download.volumeConfig = {
        type = "bind";
        device = "/media/download/qbittorrent";
      };

      volumes.qbittorrent-config.volumeConfig = {
        type = "bind";
        device = config.myServices.qbittorrent.containerConfig.volumes.qbittorrent-config;
      };

      containers.qbittorrent = {
        autoStart = true;

        unitConfig = {
          # required for networking
          Requires = [ "gluetun.service" ];
          After = [ "gluetun.service" ];
        };

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
            TZ = "Europe/Berlin";

            WEBUI_PORT = "8080";
            TORRENTING_PORT = "6881";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/ca.crt:/usr/local/share/ca-certificates/ca.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.qbittorrent-config.ref}:/config:U"
            "${volumes.qbittorrent-download.ref}:/download:U"
          ];
        };
      };
    };
}
