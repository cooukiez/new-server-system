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
in
{
  systemd.tmpfiles.rules = [
    "Z /etc/certs 0400 ${uid} ${gid} -"

    "d /opt 0755 ${uid} ${gid} -"
    "d /media 0755 ${uid} ${gid} -"
    "d /data 0755 ${uid} ${gid} -"
  ]
  ++ (mkRules "media" mediaDirs)
  ++ (mkRules "data" dataDirs);
}
