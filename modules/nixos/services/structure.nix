/*
  modules/nixos/services/structure.nix

  part of der-home-server
  created 2026-04-02
*/

{
  systemd.tmpfiles.rules = [
    "Z /etc/cert 0400 10000 10000 -"

    # auth
    "d /opt/authelia 0755 10000 10000 -"
    "d /opt/authelia/config 0755 10000 10000 -"

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

    #
    # services
    #
    "d opt/immich 0755 10000 10000 -"
    "d opt/immich/db 0755 10000 10000 -"

    # media directories
    "d /media 0755 10000 10000 -"
    "d /media/photos 0755 10000 10000 -"
  ];
}
