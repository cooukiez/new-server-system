/*
  modules/nixos/services/tmpfiles.nix

  part of der-home-server
  created 2026-04-02
*/

{
  systemd.tmpfiles.rules = [
    "d /opt/adguardhome 0755 10000 10000 -"
    "d /opt/adguardhome/conf 0755 10000 10000 -"
    "d /opt/adguardhome/work 0755 10000 10000 -"

    "d /opt/caddy 0755 10000 10000 -"
    "d /opt/caddy/config 0755 10000 10000 -"
    "d /opt/caddy/data 0755 10000 10000 -"
  ];
}
