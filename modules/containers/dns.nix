/*
  modules/containers/dns.nix

  part of server system
  created 2026-04-19
*/
{
  config,
  pkgs,
  hostConfig,
  images,
  ports,
  ...
}:
let
  adguardSettings = {
    http = {
      address = "0.0.0.0:3000";
    };

    dns =
      let
        ips = hostConfig.dnsServers;
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
          answer = "${hostConfig.staticIP}";
        }
        {
          enabled = true;
          domain = "*.home.lan";
          answer = "${hostConfig.staticIP}";
        }
        {
          enabled = true;
          domain = "*.home.lan.fritz.box";
          answer = "${hostConfig.staticIP}";
        }
      ];
    };

    querylog = {
      interval = "2160h";
    };

    statistics = {
      interval = "2160h";
    };

    schema_version = 33;
  };
in
{
  myServices.adguard = {
    serviceConfig = {
      description = "Private DNS Server";
      serviceType = "Networking";

      subdomain = "dns";
      port = ports.adguard;

      policy = "two_factor";
      group = "admins";

      icon = "adguard-home";
    };
  };

  home.file."containers/adguard/AdGuardHome.yaml".source =
    (pkgs.formats.yaml { }).generate "adguard-settings"
      adguardSettings;

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.adguard-conf.volumeConfig = {
        type = "bind";
        device = "/opt/adguard/conf";
      };

      volumes.adguard-work.volumeConfig = {
        type = "bind";
        device = "/opt/adguard/work";
      };

      containers.adguard = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-adguard" ''
              ${pkgs.coreutils}/bin/cp ${config.home.homeDirectory}/containers/adguard/AdGuardHome.yaml /opt/adguard/conf/AdGuardHome.yaml
              ${pkgs.coreutils}/bin/chmod 644 /opt/adguard/conf/AdGuardHome.yaml
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.adguard}";
          name = "adguard";
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
