/*
  modules/containers/homepage.nix

  part of der-home-server
  created 2026-04-19
*/

{
  config,
  pkgs,
  lib,
  hostConfig,
  images,
  ports,
  publicServices,
  ...
}:
let
  hostInt = "http://host.containers.internal";

  groupedData = lib.groupBy (s: s.serviceConfig.serviceType) (lib.attrValues publicServices);

  autoGroups = lib.mapAttrsToList (name: services: {
    "${name}" = map (
      s: mkSvc s.serviceConfig.name s.serviceConfig.icon s.serviceConfig.href s.serviceConfig.description
    ) services;
  }) (lib.removeAttrs groupedData [ "Networking" ]);

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
    tailscale = "https://login.tailscale.com/admin/machines";
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

    maxGroupColumns = 6;
    layout = {
      "Apps" = {
        style = "row";
        columns = 6;
      };

      "Restricted" = {
        style = "row";
        columns = 6;
      };

      "Groups" = {
        style = "column";
        columns = 4;

        "Networking".style = "column";
        "Monitoring".style = "column";
        "Services".style = "column";
        "System Monitor".style = "column";
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
              url = "${hostInt}:${toString ports.caddyAdmin}";
            };
          };
        }
        {
          "AdGuard Home" = {
            icon = config.myServices.adguard.serviceConfig.icon;
            href = config.myServices.adguard.serviceConfig.href;
            description = config.myServices.adguard.serviceConfig.description;
            widget = {
              type = "adguard";
              url = "${hostInt}:${toString config.myServices.adguard.serviceConfig.port}";
            };
          };
        }
        {
          "Tailscale" = {
            icon = "tailscale";
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
            icon = config.myServices.gluetun.serviceConfig.icon;
            href = config.myServices.gluetun.serviceConfig.href;
            description = config.myServices.gluetun.serviceConfig.description;
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
  ]
  ++ autoGroups
  ++ [
    {
      "System Monitor" = [
        (mkGlance "Info" "info" null)
        (mkGlance "CPU Usage" "cpu" false)
        (mkGlance "Memory Usage" "memory" false)
        (mkGlance "Network" "network:enp0s20f0u4" false)
        (mkGlance "Disk SSD" "disk:nvme0n1" false)
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
          source = (pkgs.formats.yaml { }).generate "homepage-${name}" value;
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
      homepage-tailscale = mkSecret "tailscale-api";
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
          image = "docker-archive:${pkgs.dockerTools.pullImage images.homepage}";
          name = "homepage";

          environments = {
            TZ = "Europe/Berlin";

            HOMEPAGE_VAR_CONFIG_CHOWN = "false";
            HOMEPAGE_VAR_PUBLIC_CHOWN = "false";

            HOMEPAGE_ALLOWED_HOSTS = "home.lan,${hostConfig.staticIP}";
            HOMEPAGE_FILE_TAILSCALE_KEY = "/run/secrets/HOMEPAGE_TAILSCALE_KEY";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # podman socket (not used currently)
            "/run/user/10000/podman/podman.sock:/run/podman/podman.sock:ro,U"

            # config
            "${config.home.homeDirectory}/containers/homepage/settings.yaml:/app/config/settings.yaml:ro,U"
            "${config.home.homeDirectory}/containers/homepage/widgets.yaml:/app/config/widgets.yaml:ro,U"
            "${config.home.homeDirectory}/containers/homepage/services.yaml:/app/config/services.yaml:ro,U"
            "${config.home.homeDirectory}/containers/homepage/bookmarks.yaml:/app/config/bookmarks.yaml:ro,U"

            # background
            "${../../assets/background/fullres-compressed.jpg}:/app/public/images/background.jpg:ro"

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
