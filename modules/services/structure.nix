/*
  modules/nixos/services/structure.nix

  part of der-home-server
  created 2026-04-19
*/

{
  pkgs,
  hostConfig,
  ...
}:
let
  cfg = config.containerMaintenance;

  mkEnableDefault = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  uid = toString hostConfig.squ.uid;
  gid = toString hostConfig.squ.gid;

  mkRules = prefix: dirs: map (d: "d /${prefix}/${d} 0755 ${uid} ${gid} -") dirs;

  backupDirs = [
    "documents"
    "git"
    "opt"
  ];

  dataDirs = [
    "documents"
  ];

  mediaDirs = [
    "music"
    "photos"
    "download"
  ];

  mediaDownloadDirs = [
    "slskd"
    "slskd/finished"
    "slskd/incomplete"

    "deezer"
    "qbittorrent"
    "youtube"
  ];
in
{
  options.containerMaintenance = {
    containerStructure = mkEnableDefault;
  };

  config = {
    systemd.tmpfiles.rules = [
      "d /bak 0755 ${uid} ${gid} -"
      "d /data 0755 ${uid} ${gid} -"
      "d /media 0755 ${uid} ${gid} -"
      "d /opt 0755 ${uid} ${gid} -"
    ]
    ++ (mkRules "bak" backupDirs)
    ++ (mkRules "data" dataDirs)

    ++ (mkRules "media" mediaDirs)
    ++ (mkRules "media/download" mediaDownloadDirs);
  };
}
