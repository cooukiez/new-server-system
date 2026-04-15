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
      "Administration" = {
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
      "Administration" = [
        {
          "Grafana" = {
            icon = "grafana";
            href = globalAddress.grafana;
            description = "Container Monitoring Dashboard";
            widget = {
              type = "grafana";
              url = grafanaLocalAddress;
              username = "admin";
              password = "{{HOMEPAGE_VAR_GRAFANA_PW}}";
              version = 2;
            };
          };
        }
      ];
    }
    {
      "Networking" = [
        {
          "AdGuard Home" = {
            icon = "adguard-home";
            href = adguardGlobalAddress;
            description = "Private DNS Server";
            widget = {
              type = "adguard";
              url = adguardLocalAddress;
              username = "admin";
              password = "{{HOMEPAGE_VAR_ADGUARD_PW}}";
            };
          };
        }
        {
          "VNStat" = {
            icon = "mdi-chart-timeline-variant";
            href = vnstatGlobalAddress;
            description = "VNStat Dashboard";
          };
        }
      ];
    }
    {
      "Services" = [
        {
          "Paperless (Admin)" = {
            icon = "paperless";
            href = paperlessGlobalAddress;
            description = "Document Management System";
            widget = {
              type = "paperlessngx";
              url = paperlessLocalAddress;
              key = "{{HOMEPAGE_VAR_PAPERLESS_KEY}}";
            };
          };
        }
        {
          "Immich (Admin)" = {
            icon = "immich";
            href = immichGlobalAddress;
            description = "Photo Management System";
            widget = {
              type = "immich";
              url = immichLocalAddress;
              key = "{{HOMEPAGE_VAR_IMMICH_KEY}}";
              version = 2;
            };
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
              url = glancesLocalAddress;
              version = 4;
              metric = "cpu";
            };
          };
        }
        {
          "Memory Usage" = {
            widget = {
              type = "glances";
              url = glancesLocalAddress;
              version = 4;
              metric = "memory";
            };
          };
        }
        {
          "Network Usage" = {
            widget = {
              type = "glances";
              url = glancesLocalAddress;
              version = 4;
              metric = "network:eth0";
            };
          };
        }
        {
          "Disk I/O" = {
            widget = {
              type = "glances";
              url = glancesLocalAddress;
              version = 4;
              metric = "disk:sda1";
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
      homepage-grafana = mkSecret "grafana-admin";
      homepage-adguard = mkSecret "adguard-admin";
      homepage-paperless = mkSecret "paperless-key";
      homepage-immich = mkSecret "immich-key";
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
            # Map file paths from age secrets to Homepage vars
            HOMEPAGE_VAR_GRAFANA_PW = "file://${config.age.secrets.homepage-grafana.path}";
            HOMEPAGE_VAR_ADGUARD_PW = "file://${config.age.secrets.homepage-adguard.path}";
            HOMEPAGE_VAR_PAPERLESS_KEY = "file://${config.age.secrets.homepage-paperless.path}";
            HOMEPAGE_VAR_IMMICH_KEY = "file://${config.age.secrets.homepage-immich.path}";
          };

          volumes = [
            "/run/user/10000/podman/podman.sock:/run/podman/podman.sock:ro"
            # Mount the generated configs
            "${config.home.homeDirectory}/containers/homepage/settings.yaml:/app/config/settings.yaml:ro"
            "${config.home.homeDirectory}/containers/homepage/widgets.yaml:/app/config/widgets.yaml:ro"
            "${config.home.homeDirectory}/containers/homepage/services.yaml:/app/config/services.yaml:ro"
            # Mount background image
            "${./background.png}:/app/public/images/background.png:ro"
          ];

          publishPorts = [
            "${toString ports.homepage}:3000/tcp"
          ];
        };
      };
    };
}
