/*
  modules/nixos/services/structure.nix

  part of der-home-server
  created 2026-04-10
*/

{
  pkgs,
  globalConfig,
  ...
}:
let
  mkOpt = path: "d /opt/${path} 0755 ${globalConfig.squUID} 10000 -";
  mkMedia = path: "d /media/${path} 0755 10000 10000 -";
  mkData = path: "d /data/${path} 0755 10000 10000 -";
in
{
  systemd.tmpfiles.rules = [
    "Z /etc/certs 0400 10000 10000 -"

    # auth
    "d /opt/authelia 0755 10000 10000 -"
    "d /opt/authelia/config 0755 10000 10000 -"
    "d /opt/lldap 0755 10000 10000 -"
    "d /opt/lldap/data 0755 10000 10000 -"

    # dns
    "d /opt/adguardhome 0755 10000 10000 -"
    "d /opt/adguardhome/conf 0755 10000 10000 -"
    "d /opt/adguardhome/work 0755 10000 10000 -"

    # reverse_proxy
    "d /opt/caddy 0755 10000 10000 -"
    "d /opt/caddy/config 0755 10000 10000 -"
    "d /opt/caddy/data 0755 10000 10000 -"

    # database
    "d /opt/postgres 0755 10000 10000 -"
    "d /opt/postgres/data 0755 10000 10000 -"
    "d /opt/postgres/pgadmin 0755 10000 10000 -"

    # vpn
    "d /opt/gluetun 0755 10000 10000 -"
    "d /opt/gluetun/data 0755 10000 10000 -"

    # monitor
    "d /opt/grafana 0755 10000 10000 -"
    "d /opt/grafana/provisioning 0755 10000 10000 -"

    "d /opt/grafana/data 0755 10000 10000 -"
    "d /opt/grafana/plugins 0755 10000 10000 -"
    "d /opt/grafana/log 0755 10000 10000 -"

    "d /opt/prometheus 0755 10000 10000 -"
    "d /opt/prometheus/data 0755 10000 10000 -"

    "d /opt/loki 0755 10000 10000 -"
    "d /opt/loki/data 0755 10000 10000 -"

    #
    # services
    #
    "d /opt/immich 0755 10000 10000 -"
    "d /opt/immich/db 0755 10000 10000 -"
    "d /opt/immich/ml-cache 0755 10000 10000 -"

    "d /opt/node-red 0755 10000 10000 -"
    "d /opt/node-red/data 0755 10000 10000 -"

    "d /opt/lidarr 0755 10000 10000 -"
    "d /opt/lidarr/data 0755 10000 10000 -"
    "d /opt/lidarr/lists 0755 10000 10000 -"

    "d /opt/cmdarr 0755 10000 10000 -"
    "d /opt/cmdarr/data 0755 10000 10000 -"

    "d /opt/slskd 0755 10000 10000 -"
    "d /opt/slskd/data 0755 10000 10000 -"

    "d /opt/jellyfin 0755 10000 10000 -"
    "d /opt/jellyfin/config 0755 10000 10000 -"
    "d /opt/jellyfin/data 0755 10000 10000 -"
    "d /opt/jellyfin/cache 0755 10000 10000 -"
    "d /opt/jellyfin/log 0755 10000 10000 -"

    "d /opt/qbittorrent 0755 10000 10000 -"
    "d /opt/qbittorrent/data 0755 10000 10000 -"

    "d /opt/transfer-sh 0755 10000 10000 -"
    "d /opt/transfer-sh/data 0755 10000 10000 -"

    "d /opt/gitea 0755 10000 10000 -"
    "d /opt/gitea/data 0755 10000 10000 -"

    "d /opt/papra 0755 10000 10000 -"
    "d /opt/papra/data 0755 10000 10000 -"

    "d /opt/radicale 0755 10000 10000 -"
    "d /opt/radicale/config 0755 10000 10000 -"
    "d /opt/radicale/data 0755 10000 10000 -"

    "d /opt/ebk 0755 10000 10000 -"
    "d /opt/ebk/data 0755 10000 10000 -"
    "d /opt/ebk/log 0755 10000 10000 -"

    #
    # media directories
    #
    "d /media 0755 10000 10000 -"

    "d /media/music 0755 10000 10000 -"
    "d /media/photos 0755 10000 10000 -"

    # download folder structure
    "d /media/download 0755 10000 10000 -"

    "d /media/download/slskd 0755 10000 10000 -"
    "d /media/download/slskd/finished 0755 10000 10000 -"
    "d /media/download/slskd/incomplete 0755 10000 10000 -"

    "d /media/download/deezer 0755 10000 10000 -"
    "d /media/download/qbittorrent 0755 10000 10000 -"

    #
    # data directories
    #
    "d /data 0755 10000 10000 -"
    "d /data/documents 0755 10000 10000 -"
  ];
}
