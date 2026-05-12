/*
  modules/containers/services/media/qbittorrent.nix

  part of server system
  created 2026-04-17
*/

{
  config,
  pkgs,
  images,
  ports,
  downloadPath,
  ...
}:
{
  myServices.qbittorrent = {
    serviceConfig = {
      name = "qBittorrent";
      description = "Torrent / Magnet Management";
      serviceType = "Restricted";

      subdomain = "torrent";
      port = ports.qBittorrent;

      policy = "bypass";

      icon = "qbittorrent";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.qbittorrent-download.volumeConfig = {
        type = "bind";
        device = "${downloadPath}/qbittorrent";
      };

      volumes.qbittorrent-config.volumeConfig = {
        type = "bind";
        device = "/opt/qbittorrent/data";
      };

      containers.qbittorrent = {
        autoStart = true;

        unitConfig = {
          Requires = [ "gluetun.service" ];
          After = [ "gluetun.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.qbittorrent}";
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
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.qbittorrent-config.ref}:/config:U"
            "${volumes.qbittorrent-download.ref}:/download:U"
          ];
        };
      };
    };
}
