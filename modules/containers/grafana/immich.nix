/*
  modules/containers/grafana/immich.nix

  part of der-home-server
  created 2026-04-10
*/

{
  mkDashboard,
  mkPanel,
}:
let
  dashboardName = "Immich";
  appName = "Immich";
  containerName = "immich";
  networkRelevantContainer = "immich-server";

  immichServerName = "immich-server";
  immichMachineLearningName = "immich-ml";
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
            (
              sum(
                rate(podman_container_cpu_seconds_total[5m]) 
                * on(id) group_left(name) 
                podman_container_info{name=~".*${containerName}.*"}
              ) by (name) * 100
            ) / 8
          '';
          legendFormat = "__auto";
          range = true;
          refId = "A";
        }
      ];
    })
    (mkPanel {
      name = "${appName} Memory Usage";
      id = 2;

      datasourceType = "prometheus";
      unit = "bytes";

      gridPos = {
        x = 0;
        y = 8;
        w = 12;
        h = 8;
      };

      targets = [
        {
          editorMode = "code";
          expr = ''
            sum(
              podman_container_mem_usage_bytes 
              * on(id) group_left(name) 
              podman_container_info{name=~".*${containerName}.*"}
            ) by (name)
          '';
          legendFormat = "__auto";
          range = true;
          refId = "A";
        }
      ];
    })
    (mkPanel {
      name = "${appName} Network Usage";
      id = 3;

      datasourceType = "prometheus";
      unit = "bytes";

      gridPos = {
        x = 0;
        y = 16;
        w = 12;
        h = 8;
      };

      targets = [
        {
          editorMode = "code";
          expr = ''
            sum(
              rate(podman_container_net_input_total[5m]) 
              * on(id) group_left(name) 
              podman_container_info{name=~".*${networkRelevantContainer}.*"}
            )
          '';
          legendFormat = "Total Incoming";
          instant = false;
          range = true;
          refId = "A";
        }
        {
          editorMode = "code";
          expr = ''
            sum(
              rate(podman_container_net_output_total[5m]) 
              * on(id) group_left(name) 
              podman_container_info{name=~".*${networkRelevantContainer}.*"}
            )
          '';
          legendFormat = "Total Outgoing";
          instant = false;
          range = true;
          refId = "B";
        }
      ];
    })

    # right side (logs)
    (mkPanel {
      name = "${appName} Server Logs";
      id = 4;

      datasourceType = "loki";

      gridPos = {
        x = 12;
        y = 0;
        w = 12;
        h = 8;
      };

      targets = [
        {
          editorMode = "code";
          expr = ''
            {syslog_identifier="${immichServerName}"}
          '';
          direction = "backward";
          queryType = "range";
          refId = "A";
        }
      ];
    })

    (mkPanel {
      name = "${appName} Machine Learning Logs";
      id = 5;

      datasourceType = "loki";

      gridPos = {
        x = 12;
        y = 8;
        w = 12;
        h = 8;
      };

      targets = [
        {
          editorMode = "code";
          expr = ''
            {syslog_identifier="${immichMachineLearningName}"}
          '';
          direction = "backward";
          queryType = "range";
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
