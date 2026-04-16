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

  mediaDirs = [
    "music"
    "photos"

    "download/slskd/finished"
    "download/slskd/incomplete"

    "download/deezer"

    "download/qbittorrent"
  ];

  dataDirs = [
    "documents"
  ];

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

    # services
    "immich/db"
    "immich/ml-cache"

    "node-red/data"

    "lidarr/data"
    "lidarr/lists"

    "cmdarr/data"

    "slskd/data"

    "jellyfin/config"
    "jellyfin/data"
    "jellyfin/cache"
    "jellyfin/log"

    "qbittorrent/data"

    "transfer-sh/data"

    "gitea/data"
    "papra/data"

    "radicale/config"
    "radicale/data"

    "ebk/data"
    "ebk/log"
  ];
in
{
  systemd.tmpfiles.rules = [
    "Z /etc/certs 0400 ${uid} ${gid} -"

    "d /opt 0755 ${uid} ${gid} -"
    "d /media 0755 ${uid} ${gid} -"
    "d /data 0755 ${uid} ${gid} -"
  ]
  ++ (mkRules "opt" optDirs)
  ++ (mkRules "media" mediaDirs)
  ++ (mkRules "data" dataDirs);
}
