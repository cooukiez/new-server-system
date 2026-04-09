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

  # grafana paths inside container
  grafanaSettingsPath = "/etc/grafana/grafana.ini";
  grafanaCertPath = "/etc/grafana/root.crt";
  grafanaProvisioningPath = "/etc/grafana/provisioning";
  grafanaDataPath = "/var/lib/grafana";

  # prometheus paths inside container
  prometheusConfigPath = "/etc/prometheus/prometheus.yml";
  prometheusDataPath = "/prometheus";

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
    ];
  };
in
{
  # grafana
  home.file."containers/grafana/grafana.ini" = {
    source = grafanaSettingsFormat.generate "grafana.ini" grafanaSettings;
  };

  home.file."containers/grafana/root.crt".source = ../../home.lan.crt;
  age.secrets.grafana-oauth.file = ../../secrets/grafana-oauth.age;

  home.file."containers/grafana/provisioning/datasources/prometheus.yaml".text = ''
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus:9090
        isDefault: true
  '';

  # prometheus
  home.file."containers/prometheus/prometheus.yml".source =
    prometheusSettingsFormat.generate "prometheus.yml" prometheusSettings;

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.monitoring.networkConfig = {
        networkConfig = {
          internal = false;
        };
      };

      volumes.grafana-data.volumeConfig = {
        type = "bind";
        device = "/opt/grafana/data";
      };

      volumes.prometheus-data.volumeConfig = {
        type = "bind";
        device = "/opt/prometheus/data";
      };

      containers.grafana = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
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
            "${config.home.homeDirectory}/containers/grafana/provisioning:${grafanaProvisioningPath}:ro"

            # secrets
            "${config.age.secrets.grafana-oauth.path}:/run/secrets/OAUTH_SECRET:ro"
            "${config.home.homeDirectory}/containers/grafana/root.crt:${grafanaCertPath}:ro"

            # volumes
            "${volumes.grafana-data.ref}:/var/lib/grafana"
          ];

          publishPorts = [
            "${toString ports.grafana}:3000/tcp"
          ];

          environments = {
            GF_PLUGINS_PREINSTALL = "grafana-clock-panel,grafana-simple-json-datasource";

            GF_PATHS_CONFIG = grafanaSettingsPath;
            GF_PATHS_PROVISIONING = grafanaProvisioningPath;

            GF_PATHS_DATA = grafanaDataPath;
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
    };
}
