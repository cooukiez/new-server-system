/*
  modules/containers/monitor.nix

  part of server system
  created 2026-04-19
*/

{
  config,
  pkgs,
  images,
  ports,
  ...
}:
let
  prometheusDatasource = "PBFA97CFB590B2093";
  lokiDatasource = "P8E80F9AEF21F6940";

  #
  # paths inside container
  #
  grafanaPaths = {
    root = "/grafana";

    config = "/grafana/grafana.ini";
    provisioning = "/grafana/provisioning";

    cert = "/certs/ca.crt";

    data = "/grafana/data";
    plugins = "/grafana/plugins";
    log = "/grafana/log";
  };

  prometheusPaths = {
    root = "/prometheus";

    config = "/prometheus/prometheus.yml";
    data = "/prometheus/data";
  };

  lokiPaths = {
    root = "/loki";

    config = "/loki/local-config.yml";
    chunks = "/loki/chunks";
    rules = "/loki/rules";
  };

  #
  # grafana settings
  #
  grafanaSettings = {
    server = {
      protocol = "http";
      http_port = 3000;
      domain = config.myServices.grafana.serviceConfig.domain;
      root_url = config.myServices.grafana.serviceConfig.href;
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

    "auth.generic_oauth" = {
      enabled = true;
      name = "Authelia";
      icon = "signin";

      client_id = "grafana";
      client_secret = "$__file{/run/secrets/GRAFANA_CLIENT_KEY}";

      scopes = "openid profile email groups";
      empty_scopes = false;

      auth_url = "https://auth.home.lan/api/oidc/authorization";
      token_url = "https://auth.home.lan/api/oidc/token";
      api_url = "https://auth.home.lan/api/oidc/userinfo";

      login_attribute_path = "preferred_username";
      groups_attribute_path = "groups";
      name_attribute_path = "name";
      allow_assign_grafana_admin = true;

      use_pkce = true;
      auth_style = "InHeader";

      tls_client_ca = "/certs/ca.crt";

      role_attribute_path = "contains(groups, 'admins') && 'Admin' || contains(groups, 'editors') && 'Editor' || 'Viewer'";
    };
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
    glances = {
      serviceConfig = {
        name = "Glances";
        description = "System Dashboard";
        serviceType = "Monitoring";

        subdomain = "glances";
        port = ports.glances;

        policy = "two_factor";
        group = "admins";

        icon = "glances";
      };
    };

    grafana = {
      serviceConfig = {
        name = "Grafana";
        description = "Container / Monitoring Dashboard";
        serviceType = "Monitoring";

        subdomain = "monitor";
        port = ports.grafana;

        policy = "bypass";

        icon = "grafana";
      };
    };

    prometheus = {
      serviceConfig = {
        name = "Prometheus";
        description = "System Statistics Datasource";
        serviceType = "Monitoring";

        subdomain = "prometheus";
        port = ports.prometheus;

        policy = "two_factor";
        group = "admins";

        icon = "prometheus";
      };
    };
  };

  # grafana
  home.file."containers/grafana/grafana.ini".source =
    (pkgs.formats.ini { }).generate "grafana-settings"
      grafanaSettings;

  home.file."containers/grafana/provisioning/datasources/datasources.yaml".source =
    (pkgs.formats.yaml { }).generate "grafana-datasource-settings"
      grafanaDatasourceSettings;

  # prometheus
  home.file."containers/prometheus/prometheus.yml".source =
    (pkgs.formats.yaml { }).generate "prometheus-settings"
      prometheusSettings;

  # loki
  home.file."containers/loki/loki.yaml".source =
    (pkgs.formats.yaml { }).generate "loki-settings"
      lokiSettings;

  age.secrets =
    let
      mkSecret = name: {
        file = ../../secrets/containers/grafana/${name}.age;
      };
    in
    {
      grafana-client-key = mkSecret "s_auth-client";
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
            grafana-provisioning = "/opt/grafana/provisioning";
            grafana-data = "/opt/grafana/data";
            grafana-plugins = "/opt/grafana/plugins";
            grafana-log = "/opt/grafana/log";

            prometheus-data = "/opt/prometheus/data";
            loki-data = "/opt/loki/data";
          };

      containers.grafana = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-grafana" ''
              ${pkgs.coreutils}/bin/cp -rfL ${config.home.homeDirectory}/containers/grafana/provisioning/. /opt/grafana/provisioning/
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.grafana}";
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
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # config
            "${config.home.homeDirectory}/containers/grafana/grafana.ini:${grafanaPaths.config}:ro,U"

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
          image = "docker-archive:${pkgs.dockerTools.pullImage images.prometheus}";
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
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # config
            "${config.home.homeDirectory}/containers/prometheus/prometheus.yml:${prometheusPaths.config}:ro,U"

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
          image = "docker-archive:${pkgs.dockerTools.pullImage images.prometheus-podman-exporter}";
          name = "podman-exporter";
          networks = [ "monitoring.network" ];

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # podman socket
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
          image = "docker-archive:${pkgs.dockerTools.pullImage images.loki}";
          name = "loki";
          networks = [ "monitoring.network" ];

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # config
            "${config.home.homeDirectory}/containers/loki/loki.yaml:${lokiPaths.config}:ro,U"

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
