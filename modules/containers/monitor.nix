/*
  modules/containers/monitor.nix

  part of der-home-server
  created 2026-04-10
*/

{
  config,
  pkgs,
  ports,
  ...
}:
let
  grafanaSettingsFormat = pkgs.formats.ini { };
  prometheusSettingsFormat = pkgs.formats.yaml { };
  lokiSettingsFormat = pkgs.formats.yaml { };

  # grafana paths inside container
  grafanaSettingsPath = "/grafana/grafana.ini";
  grafanaCertPath = "/grafana/root.crt";
  grafanaProvisioningPath = "/grafana/provisioning";

  grafanaDataPath = "/grafana/data";
  grafanaPluginsPath = "/grafana/plugins";
  grafanaLogPath = "/grafana/log";

  # prometheus paths inside container
  prometheusConfigPath = "/prometheus/prometheus.yml";
  prometheusDataPath = "/prometheus/data";

  # loki paths inside container
  lokiConfigPath = "/loki/local-config.yaml";
  lokiChunksPath = "/loki/chunks";
  lokiRulesPath = "/loki/rules";

  #
  # grafana settings
  #
  grafanaVersion = "latest";
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
      data = grafanaDataPath;
      provisioning = grafanaProvisioningPath;
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
      client_secret = "$__file{/run/secrets/OAUTH_SECRET}";

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

      tls_client_ca = grafanaCertPath;

      # map authelia groups to grafana roles
      role_attribute_path = "contains(groups, 'admins') && 'Admin' || contains(groups, 'editors') && 'Editor' || 'Viewer'";
    };
  };

  #
  # prometheus settings
  #
  prometheusVersion = "latest";
  prometheusPodmanExporterVersion = "latest";
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
  lokiVersion = "latest";
  lokiSettings = {
    auth_enabled = false;
    server.http_listen_port = ports.loki;

    common = {
      instance_addr = "127.0.0.1";
      path_prefix = "/loki";
      storage.filesystem = {
        chunks_directory = lokiChunksPath;
        rules_directory = lokiRulesPath;
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

  # grafana
  home.file."containers/grafana/grafana.ini" = {
    source = grafanaSettingsFormat.generate "grafana.ini" grafanaSettings;
  };

  home.file."containers/grafana/root.crt".source = ../../home.lan.crt;
  age.secrets.grafana-oauth.file = ../../secrets/grafana-oauth.age;

  # grafana provisioning

  home.file."containers/grafana/provisioning/dashboards/dashboards.yaml".text = ''
    apiVersion: 1
    providers:
      - name: 'Default'
        orgId: 1
        folder: ""
        type: file
        disableDeletion: false
        editable: true
        options:
          path: ${grafanaProvisioningPath}/dashboards
  '';

  home.file."containers/grafana/provisioning/datasources/datasources.yaml".text = ''
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        uid: PBFA97CFB590B2093
        access: proxy
        url: http://prometheus:${toString ports.prometheus}
        isDefault: true
      - name: Loki
        type: loki
        uid: P8E80F9AEF21F6940
        url: http://loki:${toString ports.loki}
  '';

  # prometheus
  home.file."containers/prometheus/prometheus.yml".source =
    prometheusSettingsFormat.generate "prometheus.yml" prometheusSettings;

  # loki
  home.file."containers/loki/loki.yaml".source = lokiSettingsFormat.generate "loki.yaml" lokiSettings;

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

      volumes.grafana-provisioning.volumeConfig = {
        type = "bind";
        device = "/opt/grafana/provisioning";
      };

      volumes.grafana-data.volumeConfig = {
        type = "bind";
        device = "/opt/grafana/data";
      };

      volumes.grafana-plugins.volumeConfig = {
        type = "bind";
        device = "/opt/grafana/plugins";
      };

      volumes.grafana-log.volumeConfig = {
        type = "bind";
        device = "/opt/grafana/log";
      };

      volumes.prometheus-data.volumeConfig = {
        type = "bind";
        device = "/opt/prometheus/data";
      };

      volumes.loki-data.volumeConfig = {
        type = "bind";
        device = "/opt/loki/data";
      };

      containers.grafana = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";

          ExecStartPre = [
            # copy contents of provisioning into opt
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

          volumes = [
            # config
            "${config.home.homeDirectory}/containers/grafana/grafana.ini:${grafanaSettingsPath}:ro"

            # secrets
            "${config.age.secrets.grafana-oauth.path}:/run/secrets/OAUTH_SECRET:ro"
            "${config.home.homeDirectory}/containers/grafana/root.crt:${grafanaCertPath}:ro"

            # volumes
            "${volumes.grafana-provisioning.ref}:${grafanaProvisioningPath}"

            "${volumes.grafana-data.ref}:${grafanaDataPath}"
            "${volumes.grafana-plugins.ref}:${grafanaPluginsPath}"
            "${volumes.grafana-log.ref}:${grafanaLogPath}"
          ];

          publishPorts = [
            "${toString ports.grafana}:3000/tcp"
          ];

          environments = {
            GF_PLUGINS_PREINSTALL = "grafana-clock-panel,grafana-simple-json-datasource";

            GF_PATHS_CONFIG = grafanaSettingsPath;
            GF_PATHS_PROVISIONING = grafanaProvisioningPath;

            GF_PATHS_DATA = grafanaDataPath;
            GF_PATHS_PLUGINS = grafanaPluginsPath;
            GF_PATHS_LOGS = grafanaLogPath;
          };
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

          volumes = [
            # config
            "${config.home.homeDirectory}/containers/prometheus/prometheus.yml:${prometheusConfigPath}:ro"

            # volumes
            "${volumes.prometheus-data.ref}:${prometheusDataPath}"
          ];

          publishPorts = [
            "${toString ports.prometheus}:9090/tcp"
          ];

          exec = [
            "--config.file=${prometheusConfigPath}"
            "--storage.tsdb.path=${prometheusDataPath}"

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
          userns = "keep-id";

          # mount squ podman socket
          volumes = [
            "/run/user/10000/podman/podman.sock:/run/podman/podman.sock:ro"
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

          publishPorts = [ "${toString ports.loki}:3100/tcp" ];

          volumes = [
            # config
            "${config.home.homeDirectory}/containers/loki/loki.yaml:${lokiConfigPath}:ro"

            # volumes
            "${volumes.loki-data.ref}:/loki"
          ];

          exec = [
            "-config.file=${lokiConfigPath}"
          ];
        };
      };
    };
}
