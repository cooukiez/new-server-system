/*
  modules/containers/services/papra.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  pkgs,
  staticIP,
  ports,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };

  homepageVersion = "latest";

  globalAddress = {
    fritzbox = "http://192.168.178.1";

    homepage = "https://home.lan";

    adguard = "https://dns.home.lan";
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

  # homepage settings
  homepageSettings = {
    title = "homeserver";
    headerStyle = "clean";

    background = {
      image = "/images/background.png";
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
        columns = 5;

        "Networking" = {
          style = "column";
        };
        "Monitoring" = {
          style = "column";
        };
        "Services" = {
          style = "column";
          columns = 2;
        };

        "System Monitor" = {
          style = "column";
        };
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
      datetime = {
        format = {
          date = "long";
          time = "short";
          hour12 = false;
        };
      };
    }
    {
      openmeteo = {
        label = "Weather";
        latitude = "52.52";
        longitude = "13.40";
        units = "metric";
        cache = 5;
      };
    }
    {
      resources = {
        disk = "/";
      };
    }
  ];

  homepageServices = [
    {
      "Networking" = [
        {
          "Caddy" = {
            icon = "caddy";
            href = globalAddress.homepage;
            description = "Server Reverse Proxy";
            widget = {
              type = "caddy";
              url = "http://host.containers.internal:${toString ports.caddyAdmin}";
            };
          };
        }
        {
          "AdGuard Home" = {
            icon = "adguard-home";
            href = globalAddress.adguard;
            description = "Private DNS Server";
            widget = {
              type = "adguard";
              url = "http://host.containers.internal:${toString ports.adguard}";
            };
          };
        }
        {
          "Tailscale" = {
            icon = "tailscale";
            href = "https://login.tailscale.com/admin/machines";
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
            icon = "gluetun";
            href = globalAddress.gluetun;
            description = "Server VPN Provider";
            widget = {
              type = "gluetun";
              url = "http://host.containers.internal:${toString ports.gluetun}";
              version = 2;
              key = "169qzBxFa0ET26rkTWa3akmVopysVilS";
            };
          };
        }
      ];
    }
    {
      "Monitoring" = [
        {
          "Grafana" = {
            icon = "grafana";
            href = globalAddress.grafana;
            description = "Container / Monitoring Dashboard";
          };
        }
        {
          "Glances" = {
            icon = "glances";
            href = globalAddress.glances;
            description = "Server Usage Statistics";
          };
        }
        {
          "VNStat" = {
            icon = "mdi-chart-timeline-variant";
            href = globalAddress.vnstat;
            description = "VNStat Dashboard";
          };
        }
      ];
    }
    {
      "Services" = [
        #
        # media
        #
        {
          "Immich" = {
            icon = "immich";
            href = globalAddress.immich;
            description = "Photo Management System";
          };
        }
        {
          "Jellyfin" = {
            icon = "jellyfin";
            href = globalAddress.jellyfin;
            description = "Universal Media Server";
          };
        }
        {
          "Lidarr" = {
            icon = "lidarr";
            href = globalAddress.lidarr;
            description = "Music Tracker / Downloader";
          };
        }
        {
          "Slskd" = {
            icon = "slskd";
            href = globalAddress.slskd;
            description = "Soulseek Network Integration";
          };
        }
        {
          "qBittorrent" = {
            icon = "qbittorrent";
            href = globalAddress.qbittorrent;
            description = "Torrent / Magnet Downloader";
          };
        }
        #
        # organisation
        #
        {
          "Papra" = {
            icon = "papra";
            href = globalAddress.papra;
            description = "Document Management System";
          };
        }
        {
          "Gitea" = {
            icon = "gitea";
            href = globalAddress.gitea;
            description = "Selfhosted DevOps Platform";
          };
        }
        {
          "ezBookkeeping" = {
            icon = "ezbookkeeping";
            href = globalAddress.ebk;
            description = "Personal Finance Management";
          };
        }
        #
        # other
        #
        {
          "transfer.sh" = {
            icon = "https://avatars.githubusercontent.com/u/5444419?s=48&v=4";
            href = globalAddress.transfer-sh;
            description = "Convenient File Transfer";
          };
        }
        {
          "Node-RED" = {
            icon = "https://avatars.githubusercontent.com/u/5375661?s=48&v=4";
            href = globalAddress.node-red;
            description = "Automation Flow System";
          };
        }
      ];
    }
    {
      "System Monitor" = [
        {
          "Info" = {
            widget = {
              type = "glances";
              url = "http://host.containers.internal:${toString ports.glances}";
              version = 4;
              metric = "info";
            };
          };
        }
        {
          "CPU Usage" = {
            widget = {
              type = "glances";
              url = "http://host.containers.internal:${toString ports.glances}";
              version = 4;
              metric = "cpu";
              chart = false;
            };
          };
        }
        {
          "Memory Usage" = {
            widget = {
              type = "glances";
              url = "http://host.containers.internal:${toString ports.glances}";
              version = 4;
              metric = "memory";
              chart = false;
            };
          };
        }
        {
          "Network Usage" = {
            widget = {
              type = "glances";
              url = "http://host.containers.internal:${toString ports.glances}";
              version = 4;
              metric = "network:enp0s20f0u4";
              chart = false;
            };
          };
        }
        {
          "Disk SSD" = {
            widget = {
              type = "glances";
              url = "http://host.containers.internal:${toString ports.glances}";
              version = 4;
              metric = "disk:nvme0n1";
              chart = false;
            };
          };
        }
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
  home.file = {
    "containers/homepage/settings.yaml".source =
      settingsFormat.generate "settings.yaml" homepageSettings;
    "containers/homepage/widgets.yaml".source = settingsFormat.generate "widgets.yaml" homepageWidgets;
    "containers/homepage/services.yaml".source =
      settingsFormat.generate "services.yaml" homepageServices;
    "containers/homepage/bookmarks.yaml".source =
      settingsFormat.generate "bookmarks.yaml" homepageBookmarks;
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../secrets/${name}.age;
      };
    in
    {
      homepage-tailscale = mkSecret "tailscale-api";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes;
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
          userns = "keep-id:uid=0,gid=0";

          environments = {
            HOMEPAGE_ALLOWED_HOSTS = "home.lan,${staticIP}";

            HOMEPAGE_FILE_TAILSCALE_KEY = "/run/secrets/HOMEPAGE_TAILSCALE_KEY";
          };

          volumes = [
            "/run/user/10000/podman/podman.sock:/run/podman/podman.sock:ro"

            # config
            "${config.home.homeDirectory}/containers/homepage/settings.yaml:/app/config/settings.yaml:ro"
            "${config.home.homeDirectory}/containers/homepage/widgets.yaml:/app/config/widgets.yaml:ro"
            "${config.home.homeDirectory}/containers/homepage/services.yaml:/app/config/services.yaml:ro"
            "${config.home.homeDirectory}/containers/homepage/bookmarks.yaml:/app/config/bookmarks.yaml:ro"

            # background
            "${./assets/background-fullres.png}:/app/public/images/background.png:ro"

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
