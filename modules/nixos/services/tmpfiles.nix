{
  systemd.tmpfiles.rules = [
    "d /opt/adguardhome 0755 10000 10000 -"
    "d /opt/adguardhome/work 0755 10000 10000 -"
    "d /opt/adguardhome/conf 0755 10000 10000 -"
  ];
}