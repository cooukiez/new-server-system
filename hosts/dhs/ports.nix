/*
  hosts/dhs/ports.nix

  part of server system
  created 2026-04-20
*/

{
  #
  # core
  #
  authelia = 9091;
  lldap = 3890;
  lldapWeb = 17170;

  # database
  postgres = 5432;
  pgadmin = 5434;

  # dns
  adguard = 3000;
  dns = 53;

  # homepage
  homepage = 8000;

  # monitor
  grafana = 3005;
  loki = 3100;
  prometheus = 9090;

  # reverse proxy
  caddyAdmin = 2019;
  caddyHttp = 80;
  caddyHttps = 443;

  # vpn
  gluetun = 8888;
  gluetunWebUI = 9888;

  # backup
  borg = 8081;

  #
  # services
  #
  nodeRed = 1880;
  crontab = 8030;

  # documents
  atuin = 8989;
  ebk = 8040;
  linkwarden = 3020;
  mailArchiver = 5000;
  memos = 5230;
  papra = 1221;
  radicale = 5232;
  stirling = 9010;
  trek = 3010;

  # git
  gitea = 222;
  giteaHttp = 3030;
  opengist = 2222;
  opengistHttp = 6157;

  # immich
  immich = 2283;

  # media
  jellyfin = 8096;

  # music
  cmdarr = 8688;
  lidarr = 8686;
  lidarrLists = 18686;
  slskdHttp = 5030;
  slskdHttps = 5031;
  slskdPeer = 50300;

  # qbittorrent
  qBittorrent = 6880;
  qBittorrentTorrenting = 6881;

  # transfer-sh
  transferSH = 8010;

  # vnstat
  vnstat = 5010;

  #
  # system level
  #
  glances = 61208;
  nodeExporter = 9100;
  promtailExporter = 9080;
}
