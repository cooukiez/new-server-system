/*
  modules/containers/services/papra.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  pkgs,
  lib,
  globalConfig,
  ports,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };

  homepageVersion = "latest";

  hostInt = "http://host.containers.internal";

  mkSvc = name: icon: href: desc: {
    "${name}" = {
      inherit icon href;
      description = desc;
    };
  };

  mkGlance = name: metric: chart: {
    "${name}".widget = {
      inherit metric chart;
      type = "glances";
      url = "${hostInt}:${toString ports.glances}";
      version = 4;
    };
  };

  globalAddress = {
    fritzbox = "http://192.168.178.1";

    homepage = "https://home.lan";

    adguard = "https://dns.home.lan";
    tailscale = "https://login.tailscale.com/admin/machines";
    gluetun = "https://vpn.home.lan";

    grafana = "https://monitor.home.lan";
    glances = "https://glances.home.lan";
    vnstat = "https://vnstat.home.lan";

    transfer-sh = "https://transfer.home.lan";
    node-red = "https://flow.home.lan";

    immich = "https://immich.home.lan";
    jellyfin = "https://jellyfin.home.lan";

    lidarr = "https://lidarr.home.lan";
    slskd = "https://slskd.home.lan";
    qbittorrent = "https://torrent.home.lan";

    papra = "https://papra.home.lan";
    gitea = "https://git.home.lan";
    ebk = "https://finance.home.lan";
  };

  icons = {
    caddy = "caddy";
    adguard = "adguard-home";
    tailscale = "tailscale";
    gluetun = "gluetun";

    grafana = "grafana";
    glances = "glances";
    vnstat = "mdi-chart-timeline-variant";

    immich = "immich";
    jellyfin = "jellyfin";
    lidarr = "lidarr";
    slskd = "slskd";
    qbittorrent = "qbittorrent";

    papra = "papra";
    gitea = "gitea";
    ebk = "ezbookkeeping";

    transfer-sh = "https://avatars.githubusercontent.com/u/5444419?s=48&v=4";
    node-red = "https://avatars.githubusercontent.com/u/5375661?s=48&v=4";
  };

  # homepage settings
  homepageSettings = {
    title = "homeserver";
    headerStyle = "clean";

    background = {
      image = "/images/background.jpg";
      saturate = 75;
      brightness = 70;
      opacity = 100;
    };

    cardBlur = "md";
    theme = "dark";
    color = "slate";

    disableUpdateCheck = true;

    maxGroupColumns = 5;
    layout = {
      "Groups" = {
        style = "column";
        columns = 4;

        "Networking" = {
          style = "column";
        };
        "Monitoring" = {
          style = "column";
        };
        "Services" = {
          style = "column";
        };

        "System Monitor" = {
          style = "column";
        };
      };

      "Apps" = {
        style = "row";
        columns = 5;
      };
    };
  };

  homepageWidgets = [
    {
      greeting = {
        text = "Homeserver";
        help = true;
      };
    }
    {
      resources = {
        disk = "/";
      };
    }
    {
      search = {
        provider = "duckduckgo";
        focus = true;
        target = "_blank";
        showSearchSuggestions = true;
      };
    }
    /*
      {
        datetime = {
          format = {
            date = "long";
            time = "short";
            hour12 = false;
          };
        };
      }
    */
    /*
      {
        openmeteo = {
          label = "Weather";
          latitude = "52.52";
          longitude = "13.40";
          units = "metric";
          cache = 5;
        };
      }
    */
  ];

  homepageServices = [
    {
      "Networking" = [
        {
          "Caddy" = {
            icon = icons.caddy;
            href = globalAddress.homepage;
            description = "Server Reverse Proxy";
            widget = {
              type = "caddy";
              url = "${hostInt}:${toString ports.caddyAdmin}";
            };
          };
        }
        {
          "AdGuard Home" = {
            icon = icons.adguard;
            href = globalAddress.adguard;
            description = "Private DNS Server";
            widget = {
              type = "adguard";
              url = "${hostInt}:${toString ports.adguard}";
            };
          };
        }
        {
          "Tailscale" = {
            icon = icons.tailscale;
            href = globalAddress.tailscale;
            description = "Bridge Internal Network";
            widget = {
              type = "tailscale";
              deviceid = "nB49HQJyWv11CNTRL";
              key = "{{HOMEPAGE_FILE_TAILSCALE_KEY}}";
            };
          };
        }
        {
          "Gluetun / VPN" = {
            icon = icons.gluetun;
            href = globalAddress.gluetun;
            description = "Server VPN Provider";
            widget = {
              type = "gluetun";
              url = "${hostInt}:${toString ports.gluetun}";
              version = 2;
              key = "169qzBxFa0ET26rkTWa3akmVopysVilS";
            };
          };
        }
      ];
    }
    {
      "Monitoring" = [
        (mkSvc "Grafana" icons.grafana globalAddress.grafana "Container / Monitoring Dashboard")
        (mkSvc "Glances" icons.glances globalAddress.glances "Server Usage Statistics")
        (mkSvc "VNStat" icons.vnstat globalAddress.vnstat "VNStat Dashboard")
      ];
    }
    {
      "Services" = [
        (mkSvc "Node-RED" icons.node-red globalAddress.node-red "Automation Flow System")
        (mkSvc "transfer.sh" icons.transfer-sh globalAddress.transfer-sh "Convenient File Transfer")
      ];
    }
    {
      "System Monitor" = [
        (mkGlance "Info" "info" null)
        (mkGlance "CPU Usage" "cpu" false)
        (mkGlance "Memory Usage" "memory" false)
        (mkGlance "Network" "network:enp0s20f0u4" false)
        (mkGlance "Disk SSD" "disk:nvme0n1" false)
      ];
    }
    {
      "Apps" = [
        # media
        (mkSvc "Immich" icons.immich globalAddress.immich "Photo Management System")
        (mkSvc "Jellyfin" icons.jellyfin globalAddress.jellyfin "Universal Media Server")
        (mkSvc "Lidarr" icons.lidarr globalAddress.lidarr "Music Tracker / Downloader")

        # media download
        (mkSvc "Slskd" icons.slskd globalAddress.slskd "Soulseek Network Integration")
        (mkSvc "qBittorrent" icons.qbittorrent globalAddress.qbittorrent "Torrent / Magnet Management")

        # general
        (mkSvc "Papra" icons.papra globalAddress.papra "Document Management System")
        (mkSvc "Gitea" icons.gitea globalAddress.gitea "Selfhosted DevOps Platform")
        (mkSvc "ezBookkeeping" icons.ebk globalAddress.ebk "Personal Finance Management")
      ];
    }
  ];

  homepageBookmarks = [
    {
      "General" = [
        {
          "NixOS Search" = [
            {
              abbr = "NX";
              href = "https://search.nixos.org/packages";
              icon = "nixos";
            }
          ];
        }
      ];
    }
  ];
in
{
  home.file =
    lib.mapAttrs'
      (name: value: {
        name = "containers/homepage/${name}.yaml";
        value = {
          source = settingsFormat.generate "${name}.yaml" value;
        };
      })
      {
        settings = homepageSettings;
        widgets = homepageWidgets;
        services = homepageServices;
        bookmarks = homepageBookmarks;
      };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../secrets/${name}.age;
      };
    in
    {
      homepage-tailscale = mkSecret "s_tailscale-api";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      containers.homepage = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/gethomepage/homepage:${homepageVersion}";
          name = "homepage";

          environments = {
            TZ = "Europe/Berlin";

            HOMEPAGE_VAR_CONFIG_CHOWN = "false";
            HOMEPAGE_VAR_PUBLIC_CHOWN = "false";

            HOMEPAGE_ALLOWED_HOSTS = "home.lan,${globalConfig.staticIP}";
            HOMEPAGE_FILE_TAILSCALE_KEY = "/run/secrets/HOMEPAGE_TAILSCALE_KEY";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/ca.crt:/usr/local/share/ca-certificates/ca.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # podman socket (not used currently)
            "/run/user/10000/podman/podman.sock:/run/podman/podman.sock:ro,U"

            # config
            "${config.home.homeDirectory}/containers/homepage/settings.yaml:/app/config/settings.yaml:ro,U"
            "${config.home.homeDirectory}/containers/homepage/widgets.yaml:/app/config/widgets.yaml:ro,U"
            "${config.home.homeDirectory}/containers/homepage/services.yaml:/app/config/services.yaml:ro,U"
            "${config.home.homeDirectory}/containers/homepage/bookmarks.yaml:/app/config/bookmarks.yaml:ro,U"

            # background
            "${./assets/background-fullres-compressed.jpg}:/app/public/images/background.jpg:ro"

            # secrets
            "${config.age.secrets.homepage-tailscale.path}:/run/secrets/HOMEPAGE_TAILSCALE_KEY:ro"
          ];

          publishPorts = [
            "${toString ports.homepage}:3000/tcp"
          ];
        };
      };
    };
}
