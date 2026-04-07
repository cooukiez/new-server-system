{ config, ... }:
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.grafana-data.volumeConfig = {
        type = "bind";
        device = "/opt/grafana";
      };

      containers.grafana = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/grafana/grafana-enterprise:latest";
          name = "grafana";

          volumes = [
            "${volumes.grafana-data.ref}:/var/lib/grafana"
          ];

          publishPorts = [
            "3000:3000/tcp"
          ];

          environments = {
            GF_SERVER_ROOT_URL = "https://monitor.home.lan/";
            GF_PLUGINS_PREINSTALL = "grafana-clock-panel,grafana-simple-json-datasource";
          };
        };
      };
    };
}