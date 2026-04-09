{
  config,
  pkgs,
  ports,
  ...
}:
let
  settingsFormat = pkgs.formats.ini { };

  # inside container
  settingsPath = "/etc/grafana/grafana.ini";
  provisioningPath = "/etc/grafana/provisioning";
  dataPath = "/var/lib/grafana";

  grafanaVersion = "latest";
  grafanaSettings = {
    server = {
      protocol = "http";
      http_port = 3000;
      domain = "monitor.home.lan";
      root_url = "https://monitor.home.lan/";
    };

    paths = {
      data = dataPath;
      provisioning = provisioningPath;
    };

    analytics = {
      reporting_enabled = false;
      check_for_updates = false;
    };
  };
in
{
  home.file."containers/grafana/grafana.ini" = {
    source = settingsFormat.generate "grafana.ini" grafanaSettings;
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.grafana-data.volumeConfig = {
        type = "bind";
        device = "/opt/grafana/data";
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

          userns = "keep-id:uid=472,gid=472";

          volumes = [
            # config
            "${config.home.homeDirectory}/containers/grafana/grafana.ini:${settingsPath}"

            # volumes
            "${volumes.grafana-data.ref}:/var/lib/grafana"
          ];

          publishPorts = [
            "${toString ports.grafana}:3000/tcp"
          ];

          environments = {
            GF_PLUGINS_PREINSTALL = "grafana-clock-panel,grafana-simple-json-datasource";

            GF_PATHS_CONFIG = settingsPath;
            GF_PATHS_PROVISIONING = provisioningPath;

            GF_PATHS_DATA = dataPath;
          };
        };
      };
    };
}
