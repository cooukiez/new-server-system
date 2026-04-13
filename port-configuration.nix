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

  # dns
  dns = 53;
  adguard = 3000;

  # monitor
  grafana = 3005;
  prometheus = 9090;
  loki = 3100;

  # reverse proxy
  caddyHttp = 80;
  caddyHttps = 443;

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
}
