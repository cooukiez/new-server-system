/*
  modules/containers/dns.nix

  part of der-home-server
  created 2026-04-08
*/

{
  config,
  pkgs,
  globalConfig,
  ports,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };

  adguardVersion = "latest";

  adguardSettings = {
    http = {
      address = "0.0.0.0:3000";
    };

    dns =
      let
        ips = [
          "9.9.9.10"
          "149.112.112.10"
        ]
        ++ globalConfig.dnsServers;
      in
      {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;

        upstream_mode = "fastest_addr";
        upstream_timeout = "2s";
        upstream_dns = [
          "https://cloudflare-dns.com/dns-query"
          "https://mozilla.cloudflare-dns.com/dns-query"
          "https://dns.google/dns-query"
          "https://dns.quad9.net/dns-query"
          "https://unfiltered.joindns4.eu/dns-query"
        ];

        bootstrap_dns = ips;
      };

    dhcp = {
      enabled = false;
    };

    filters = [
      {
        enabled = true;
        url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
        name = "AdGuard DNS filter";
        id = 1;
      }
      {
        enabled = false;
        url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
        name = "AdAway Default Blocklist";
        id = 2;
      }
    ];

    filtering = {
      rewrites = [
        {
          enabled = true;
          domain = "home.lan";
          answer = "${globalConfig.staticIP}";
        }
        {
          enabled = true;
          domain = "*.home.lan";
          answer = "${globalConfig.staticIP}";
        }
        {
          enabled = true;
          domain = "*.home.lan.fritz.box";
          answer = "${globalConfig.staticIP}";
        }
      ];
    };

    schema_version = 33;
  };
in
{
  home.file."containers/adguardhome/AdGuardHome.yaml" = {
    source = settingsFormat.generate "AdGuardHome.yaml" adguardSettings;
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.adguard-conf.volumeConfig = {
        type = "bind";
        device = "/opt/adguardhome/conf";
      };

      volumes.adguard-work.volumeConfig = {
        type = "bind";
        device = "/opt/adguardhome/work";
      };

      containers.adguardhome = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            # adguardhome requires read and write
            "${pkgs.coreutils}/bin/cp ${config.home.homeDirectory}/containers/adguardhome/AdGuardHome.yaml /opt/adguardhome/conf/AdGuardHome.yaml"
            "${pkgs.coreutils}/bin/chmod 644 /opt/adguardhome/conf/AdGuardHome.yaml"
          ];
        };

        containerConfig = {
          image = "adguard/adguardhome:${adguardVersion}";
          name = "adguardhome";
          addCapabilities = [ "NET_BIND_SERVICE" ];

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # volumes
            "${volumes.adguard-conf.ref}:/opt/adguardhome/conf:U"
            "${volumes.adguard-work.ref}:/opt/adguardhome/work:U"
          ];

          publishPorts = [
            "${toString ports.dns}:53/tcp"
            "${toString ports.dns}:53/udp"
            "${toString ports.adguard}:3000/tcp"
          ];
        };
      };
    };
}
