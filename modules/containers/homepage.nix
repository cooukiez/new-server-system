/*
  modules/containers/services/papra.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  staticIP,
  ports,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };

  homepageVersion = "latest";

  globalAdress = {
    adguard = "https://dns.home.lan";
    grafana = "https://monitor.home.lan";
    vnstat = "https://vnstat.home.lan";
    immich = "https://immich.home.lan";
    papra = "https://papra.home.lan";
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

    layout = {
      "Monitoring" = {
        style = "row";
        columns = 5;
      };
      "Networking" = {
        style = "row";
        columns = 5;
      };
      "Services" = {
        style = "row";
        columns = 5;
      };
      "System Monitor" = {
        style = "row";
        columns = 4;
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
      "Monitoring" = [
        {
          "Grafana" = {
            icon = "grafana";
            href = globalAddress.grafana;
            description = "Container / Monitoring Dashboard";
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
      "Networking" = [
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
      ];
    }
    {
      "Services" = [
        {
          "Papra" = {
            icon = "papra";
            href = globalAddress.papra;
            description = "Document Management System";
          };
        }
        {
          "Immich" = {
            icon = "immich";
            href = globalAddress.immich;
            description = "Photo Management System";
          };
        }
      ];
    }
    {
      "System Monitor" = [
        {
          "CPU Usage" = {
            widget = {
              type = "glances";
              url = "http://127.0.0.1:${toString ports.glances}";
              version = 4;
              metric = "cpu";
            };
          };
        }
        {
          "Memory Usage" = {
            widget = {
              type = "glances";
              url = "http://127.0.0.1:${toString ports.glances}";
              version = 4;
              metric = "memory";
            };
          };
        }
        {
          "Network Usage" = {
            widget = {
              type = "glances";
              url = "http://127.0.0.1:${toString ports.glances}";
              version = 4;
              metric = "network:eth0";
            };
          };
        }
        {
          "Disk I/O" = {
            widget = {
              type = "glances";
              url = "http://127.0.0.1:${toString ports.glances}";
              version = 4;
              metric = "disk:nvme0n1";
            };
          };
        }
      ];
    }
  ];
in
{
  home.file = {
    "containers/homepage/settings.yaml".source = yamlFormat.generate "settings.yaml" homepageSettings;
    "containers/homepage/widgets.yaml".source = yamlFormat.generate "widgets.yaml" homepageWidgets;
    "containers/homepage/services.yaml".source = yamlFormat.generate "services.yaml" homepageServices;
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
      };
    in
    {
      # homepage-adguard = mkSecret "homepage/adguard-pw";
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

          addHosts = [
            "home.lan:host-gateway"
          ];

          environments = {
            HOMEPAGE_ALLOWED_HOSTS = "home.lan,${staticIP}";

            # HOMEPAGE_FILE_ADGUARD_PW = "/run/secrets/HOMEPAGE_ADGUARD_PW";
          };

          volumes = [
            "/run/user/10000/podman/podman.sock:/run/podman/podman.sock:ro"

            # config
            "${config.home.homeDirectory}/containers/homepage/settings.yaml:/app/config/settings.yaml:ro"
            "${config.home.homeDirectory}/containers/homepage/widgets.yaml:/app/config/widgets.yaml:ro"
            "${config.home.homeDirectory}/containers/homepage/services.yaml:/app/config/services.yaml:ro"

            # background
            "${./assets/background-fullres.png}:/app/public/images/background.png:ro"

            # secrets
            # "${config.age.secrets.homepage-adguard.path}:/run/secrets/HOMEPAGE_ADGUARD_PW:ro"
          ];

          publishPorts = [
            "${toString ports.homepage}:3000/tcp"
          ];
        };
      };
    };
}
