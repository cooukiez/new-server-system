/*
  modules/containers/services/media/qbittorrent.nix

  part of der-home-server
  created 2026-04-17
*/

{
  config,
  pkgs,
  ports,
  ...
}:
let
  qBittorrentVersion = "latest";
in
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
        device = "/media/download/qbittorrent";
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

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-start" ''
              ${pkgs.coreutils}/bin/mkdir -p "/opt/qbittorrent/data"
            ''}"
          ];
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
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.qbittorrent-config.ref}:/config:U"
            "${volumes.qbittorrent-download.ref}:/download:U"
          ];
        };
      };
    };
}
