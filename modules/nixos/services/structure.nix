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
    "authelia/config"
    "lldap/data"

    # infra
    "adguardhome/conf"
    "adguardhome/work"
    "caddy/config"
    "caddy/data"
    "postgres/data"
    "postgres/pgadmin"
    "gluetun/data"

    # monitoring
    "grafana/provisioning"
    "grafana/data"
    "grafana/plugins"
    "grafana/log"
    "prometheus/data"
    "loki/data"

    #
    # services
    #

    # media
    "immich/db"
    "immich/ml-cache"

    "jellyfin/config"
    "jellyfin/data"
    "jellyfin/cache"
    "jellyfin/log"

    "lidarr/data"
    "cmdarr/data"

    # downloaders
    "slskd/data"
    "qbittorrent/data"

    # genral
    "node-red/data"
    "transfer-sh/data"

    # services
    "ebk/data"
    "ebk/log"
    "gitea/data"
    "papra/data"
    "radicale/config"
    "radicale/data"
  ];

  mediaDirs = [
    "music"
    "photos"

    # media download paths
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
  ]
  ++ (mkRules "opt" optDirs)
  ++ (mkRules "media" mediaDirs)
  ++ (mkRules "data" dataDirs);
}
