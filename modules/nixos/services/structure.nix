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
  uid = toString globalConfig.squ.uid;
  gid = toString globalConfig.squ.gid;

  mkRules = prefix: dirs: map (d: "d /${prefix}/${d} 0755 ${uid} ${gid} -") dirs;

  optDirs = [
    # auth
    "authelia"
    "authelia/config"
    "lldap"
    "lldap/data"

    # infra
    "adguardhome"
    "adguardhome/conf"
    "adguardhome/work"
    "caddy"
    "caddy/config"
    "caddy/data"
    "postgres"
    "postgres/data"
    "postgres/pgadmin"
    "gluetun"
    "gluetun/data"
    "borg"
    "borg/data"
    "borg/cache"

    # monitoring
    "grafana"
    "grafana/provisioning"
    "grafana/data"
    "grafana/plugins"
    "grafana/log"
    "prometheus"
    "prometheus/data"
    "loki"
    "loki/data"

    #
    # services
    #

    # media
    "immich"
    "immich/db"
    "immich/ml-cache"
    "immich/redis"

    "jellyfin"
    "jellyfin/config"
    "jellyfin/data"
    "jellyfin/cache"
    "jellyfin/log"

    "lidarr"
    "lidarr/data"
    "cmdarr"
    "cmdarr/data"

    # downloaders
    "slskd"
    "slskd/data"
    "qbittorrent"
    "qbittorrent/data"

    # genral
    "node-red"
    "node-red/data"
    "transfer-sh"
    "transfer-sh/data"

    # services
    "ebk"
    "ebk/data"
    "ebk/log"
    "gitea"
    "gitea/data"
    "linkwarden"
    "linkwarden/data"
    "linkwarden/meili"
    "open-archiver"
    "open-archiver/data"
    "open-archiver/meili"
    "open-archiver/redis"
    "papra"
    "papra/data"
    "radicale"
    "radicale/config"
    "radicale/data"
    "stirling"
    "stirling/config"
    "stirling/log"
    "stirling/pipeline"
    "stirling/tessdata"
  ];

  mediaDirs = [
    "music"
    "photos"

    # media download paths
    "download"
    "download/deezer"
    "download/slskd/finished"
    "download/slskd/incomplete"
    "download/qbittorrent"
  ];

  dataDirs = [
    "documents"
  ];
in
{
  systemd.tmpfiles.rules = [
    "Z /etc/certs 0400 ${uid} ${gid} -"

    "d /certs 0755 ${uid} ${gid} -"
    "Z /certs 0755 ${uid} ${gid} -"

    "d /opt 0755 ${uid} ${gid} -"
    "d /media 0755 ${uid} ${gid} -"
    "d /data 0755 ${uid} ${gid} -"

    "d /bak 0755 ${uid} ${gid} -"
    "d /bak/opt 0755 ${uid} ${gid} -"
  ]
  ++ (mkRules "opt" optDirs)
  ++ (mkRules "media" mediaDirs)
  ++ (mkRules "data" dataDirs);
}
