/*
  modules/containers/monitor.nix

  part of der-home-server
  created 2026-04-12
*/

{
  config,
  pkgs,
  ports,
  ...
}:
let
  grafanaVersion = "latest";
  prometheusVersion = "latest";
  prometheusPodmanExporterVersion = "latest";
  lokiVersion = "latest";

  prometheusDatasource = "PBFA97CFB590B2093";
  lokiDatasource = "P8E80F9AEF21F6940";

  #
  # paths inside container
  #
  grafanaPaths = rec {
    root = "/grafana";

    config = "${root}/grafana.ini";
    provisioning = "${root}/provisioning";
    cert = "/certs/ca.crt";

    data = "${root}/data";
    plugins = "${root}/plugins";
    log = "${root}/log";
  };

  prometheusPaths = rec {
    root = "/prometheus";

    config = "${root}/prometheus.yml";
    data = "${root}/data";
  };

  lokiPaths = rec {
    root = "/loki";

    config = "${root}/local-config.yml";
    chunks = "${root}/chunks";
    rules = "${root}/rules";
  };

  #
  # grafana settings
  #
  grafanaSettings = {
    server = {
      protocol = "http";
      http_port = 3000;
      domain = "monitor.home.lan";
      root_url = "https://monitor.home.lan/";
    };

    security = {
      disable_initial_admin_creation = true;
      admin_user = "admin-internal";
    };

    paths = {
      data = grafanaPaths.data;
      provisioning = grafanaPaths.provisioning;
    };

    explore.enabled = false;
    help.enabled = false;
    dashboards.hide_welcome_config = true;
    news.news_feed_enabled = false;

    analytics = {
      reporting_enabled = false;
      check_for_updates = false;
    };

    auth = {
      disable_login_form = true;
      oauth_allow_insecure_email_lookup = true;
    };

    "auth.generic_oauth" = (import ./auth/oidc-client-configs.nix).grafana;
  };

  grafanaDatasourceSettings = {
    apiVersion = 1;
    datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        uid = prometheusDatasource;
        access = "proxy";
        url = "http://prometheus:${toString ports.prometheus}";
        isDefault = true;
      }
      {
        name = "Loki";
        type = "loki";
        uid = lokiDatasource;
        url = "http://loki:${toString ports.loki}";
      }
    ];
  };

  #
  # prometheus settings
  #
  prometheusSettings = {
    global = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };

    scrape_configs = [
      {
        job_name = "prometheus";
        static_configs = [ { targets = [ "127.0.0.1:9090" ]; } ];
      }
      {
        job_name = "podman";
        static_configs = [ { targets = [ "podman-exporter:9882" ]; } ];
      }
      {
        job_name = "node";
        static_configs = [
          { targets = [ "host.containers.internal:${toString ports.nodeExporter}" ]; }
        ];
      }
    ];
  };

  #
  # loki settings
  #
  lokiSettings = {
    auth_enabled = false;
    server.http_listen_port = ports.loki;

    common = {
      instance_addr = "127.0.0.1";
      path_prefix = lokiPaths.root;
      storage.filesystem = {
        chunks_directory = lokiPaths.chunks;
        rules_directory = lokiPaths.rules;
      };

      replication_factor = 1;
      ring.kvstore.store = "inmemory";
    };

    schema_config.configs = [
      {
        from = "2024-04-01";
        store = "tsdb";

        object_store = "filesystem";
        schema = "v13";

        index = {
          prefix = "index_";
          period = "24h";
        };
      }
    ];
  };
in
{
  imports = [
    ./grafana
  ];

  _module.args = {
    grafanaPaths = grafanaPaths;
  };

  myServices = {
    grafana = {
      serviceConfig = {
        description = "Container / Monitoring Dashboard";
        serviceType = "Monitoring";

        subdomain = "monitor";
        port = ports.grafana;

        policy = "bypass";

        icon = "grafana";
      };

      containerConfig = {
        files."grafana.ini" = {
          source = (pkgs.formats.ini { }).generate "grafana.ini" grafanaSettings;
        };

        files."provisioning/datasources/datasources.yaml" = {
          source = (pkgs.formats.yaml { }).generate "datasources.yaml" grafanaDatasourceSettings;
        };

        volumes = {
          grafana-provisioning = "/opt/grafana/provisiong";
          grafana-data = "/opt/grafana/data";
          grafana-plugins = "/opt/grafana/plugins";
          grafana-log = "/opt/grafana/log";
        };
      };
    };

    prometheus = {
      serviceConfig = {
        description = "System Statistics Datasource";
        serviceType = "Monitoring";

        subdomain = "prometheus";
        port = ports.prometheus;

        policy = "one_factor";
        group = "admins";

        icon = "prometheus";
      };

      containerConfig = {
        files."prometheus.yml" = {
          source = (pkgs.formats.yaml { }).generate "prometheus.yml" prometheusSettings;
        };

        volumes.prometheus-data = "/opt/prometheus/data";
      };
    };

    loki = {
      containerConfig = {
        files."loki.yaml" = {
          source = (pkgs.formats.yaml { }).generate "loki.yaml" lokiSettings;
        };

        volumes.loki-data = "/opt/loki/data";
      };
    };
  };

  age.secrets = {
    grafana-client-key.file = ../../secrets/auth/clients/s_grafana.age;
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.monitoring = {
        networkConfig = {
          internal = false;
        };
      };

      volumes =
        builtins.mapAttrs
          (name: device: {
            volumeConfig = {
              type = "bind";
              inherit device;
            };
          })
          {
            grafana-provisioning = config.myServices.grafana.containerConfig.volumes.grafana-provisioning;
            grafana-data = config.myServices.grafana.containerConfig.volumes.grafana-data;
            grafana-plugins = config.myServices.grafana.containerConfig.volumes.grafana-plugins;
            grafana-log = config.myServices.grafana.containerConfig.volumes.grafana-log;

            prometheus-data = config.myServices.prometheus.containerConfig.volumes.prometheus-data;
            loki-data = config.myServices.prometheus.containerConfig.volumes.loki-data;
          };

      containers.grafana = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "${pkgs.coreutils}/bin/cp -rfL ${config.home.homeDirectory}/containers/grafana/provisioning/. /opt/grafana/provisioning/"
          ];
        };

        containerConfig = {
          image = "docker.io/grafana/grafana-enterprise:${grafanaVersion}";
          name = "grafana";
          networks = [ "monitoring.network" ];

          userns = "keep-id:uid=472,gid=472";

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";

            GF_PLUGINS_PREINSTALL = "grafana-clock-panel,grafana-simple-json-datasource";

            GF_PATHS_CONFIG = grafanaPaths.config;
            GF_PATHS_PROVISIONING = grafanaPaths.provisioning;

            GF_PATHS_DATA = grafanaPaths.data;
            GF_PATHS_PLUGINS = grafanaPaths.plugins;
            GF_PATHS_LOGS = grafanaPaths.log;
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/ca.crt:/usr/local/share/ca-certificates/ca.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # config
            "${
              config.myServices.grafana.containerConfig.files."grafana.ini".fullPath
            }:${grafanaPaths.config}:ro,U"

            # secrets
            "${config.age.secrets.grafana-client-key.path}:/run/secrets/GRAFANA_CLIENT_KEY:ro"
          ]
          ++ (map (n: "${volumes."grafana-${n}".ref}:${grafanaPaths.${n}}") [
            "provisioning"

            "data"
            "plugins"
            "log"
          ]);

          publishPorts = [
            "${toString ports.grafana}:3000/tcp"
          ];
        };
      };

      containers.prometheus = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/prom/prometheus:${prometheusVersion}";
          name = "prometheus";
          networks = [ "monitoring.network" ];

          userns = "keep-id:uid=65534,gid=65534";

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/ca.crt:/usr/local/share/ca-certificates/ca.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # config
            "${
              config.myServices.prometheus.containerConfig."prometheus.yml".fullPath
            }:${prometheusPaths.config}:ro,U"

            # volumes
            "${volumes.prometheus-data.ref}:${prometheusPaths.data}:U"
          ];

          publishPorts = [
            "${toString ports.prometheus}:9090/tcp"
          ];

          exec = [
            "--config.file=${prometheusPaths.config}"
            "--storage.tsdb.path=${prometheusPaths.data}"

            "--web.console.libraries=/usr/share/prometheus/console_libraries"
            "--web.console.templates=/usr/share/prometheus/consoles"
          ];
        };
      };

      containers.podman-exporter = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "quay.io/navidys/prometheus-podman-exporter:${prometheusPodmanExporterVersion}";
          name = "podman-exporter";
          networks = [ "monitoring.network" ];

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # mount squ podman socket
            "/run/user/10000/podman/podman.sock:/run/podman/podman.sock:ro,U"
          ];

          environments = {
            CONTAINER_HOST = "unix:///run/podman/podman.sock";
          };

          exec = [
            "--collector.enable-all"
          ];
        };
      };

      containers.loki = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/grafana/loki:${lokiVersion}";
          name = "loki";
          networks = [ "monitoring.network" ];

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # config
            "${config.myServices.loki.containerConfig.files."loki.yaml".fullPath}:${lokiPaths.config}:ro,U"

            # volumes
            "${volumes.loki-data.ref}:/loki:U"
          ];

          exec = [
            "-config.file=${lokiPaths.config}"
          ];

          publishPorts = [ "${toString ports.loki}:3100/tcp" ];
        };
      };
    };
}
