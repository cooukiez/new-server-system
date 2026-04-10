/*
  modules/nixos/services/grafana-dashboards/immich.nix

  part of der-home-server
  created 2026-03-20
*/

{
  mkDashboard,
  mkPanel,
}:
let
  dashboardName = "Immich Container";
  appName = "Immich";
  containerName = "immich";

  immichServerName = "immich-server";
  immichMachineLearningName = "immich-ml";

  storageDevice = "/dev/sda";
in
mkDashboard {
  name = dashboardName;
  description = "${appName} container metrics";

  uid = "sdhahwq";

  editable = false;
  preload = false;

  panels = [
    # left side (stats)
    (mkPanel {
      name = "${appName} CPU Usage";
      id = 1;

      datasourceType = "prometheus";
      unit = "percent";

      gridPos = {
        x = 0;
        y = 0;
        w = 12;
        h = 8;
      };

      targets = [
        {
          editorMode = "code";
          expr = ''
            sum(
              rate(podman_container_cpu_seconds_total[5m]) 
              * on(id) group_left(name) 
              podman_container_info{name=~".*${containerName}.*"}
            ) by (name)
          '';
          legendFormat = "CPU";
          range = true;
          refId = "A";
        }
      ];
    })
  ];

  time = {
    from = "now-24h";
    to = "now";
  };
}
