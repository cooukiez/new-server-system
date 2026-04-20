/*
  port-configuration.nix

  part of der-home-server
  created 2026-04-12
*/

{
  #
  # system level
  #
  nodeExporter = 9100;
  promtailExporter = 9080;

  glances = 61208;

  #
  # core
  #

  # auth
  authelia = 9091;
  lldap = 3890;
  lldapWeb = 17170;

  # database
  postgres = 5432;
  pgadmin = 5434;

  # dns
  dns = 53;
  adguard = 3000;

  # homepage
  homepage = 8000;

  # monitor
  grafana = 3005;
  prometheus = 9090;
  loki = 3100;

  # reverse proxy
  caddyHttp = 80;
  caddyHttps = 443;
  caddyAdmin = 2019;

  # vpn
  gluetun = 8888;
  gluetunWebUI = 9888;

  #
  # services
  #

  # media
  jellyfin = 8096;

  # git
  giteaHttp = 3030;
  gitea = 222;

  # automization
  node-red = 1880;

  # documents
  papra = 1221;

  ebk = 8040;

  radicale = 5232;

  # music
  lidarr = 8686;
  lidarrLists = 18686;
  cmdarr = 8688;
  slskdHttp = 5030;
  slskdHttps = 5031;
  slskdPeer = 50300;

  # immich
  immich = 2283;

  # vnstat
  vnstat = 5010;

  # qbittorrent
  qBittorrent = 6880;
  qBittorrentTorrenting = 6881;

  # transfer-sh
  transferSH = 8010;

  # borg
  borg = 8081;

  stirling = 9010;

  open-archiver = 3010;

  linkwarden = 3020;
  mail-archiver = 5000;

  atuin = 8989;
}
