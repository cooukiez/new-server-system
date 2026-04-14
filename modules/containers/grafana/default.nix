/*
  modules/containers/grafana/default.nix

  part of der-home-server
  created 2026-04-12
*/

{
  pkgs,
  lib,
  config,
  ...
}:
let
  # dashboard generation code
  mkDashboard =
    {
      name,
      description,
      uid,
      editable,
      preload,
      time,
      panels ? [ ],
    }:
    {
      annotations = {
        list = [
          {
            builtIn = 1;
            datasource = {
              type = "grafana";
              uid = "-- Grafana --";
            };

            enable = true;
            hide = true;
            iconColor = "rgba(0, 211, 255, 1)";
            name = "Annotations & Alerts";

            target = {
              limit = 100;
              matchAny = false;
              tags = [ ];
              type = "dashboard";
            };

            type = "dashboard";
          }
        ];
      };

      title = name;
      description = description;

      id = 0;
      uid = uid;

      editable = editable;
      preload = preload;
      time = time;
      timezone = "browser";

      fiscalYearStartMonth = 0;
      graphTooltip = 0;

      inherit panels;
      links = [ ];
      tags = [ ];
      templating.list = [ ];
      timepicker = { };

      schemaVersion = 42;
      version = 2;
    };

  mkPanel =
    {
      name,
      id,

      gridPos,

      targets,
      datasourceType,

      unit ? "",
      showLegend ? false,
    }:
    let
      # default datasource objects
      datasource =
        if datasourceType == "prometheus" then
          {
            type = "prometheus";
            uid = "PBFA97CFB590B2093";
          }
        else if datasourceType == "loki" then
          {
            type = "loki";
            uid = "P8E80F9AEF21F6940";
          }
        else
          {
            type = "";
            uid = "";
          };

    in
    {
      inherit
        gridPos
        targets
        datasource
        ;

      type = if datasourceType == "loki" then "logs" else "timeseries";
      pluginVersion = "12.3.5";

      title = name;
      id = id;

      fieldConfig = {
        defaults =
          if datasourceType == "loki" then
            {
              # none
            }
          else
            {
              inherit unit;

              color.mode = "palette-classic";

              custom = {
                axisBorderShow = false;
                axisCenteredZero = false;
                axisColorMode = "text";
                axisLabel = "";
                axisPlacement = "auto";

                barAlignment = 0;
                barWidthFactor = 0.6;

                drawStyle = "line";
                fillOpacity = 0;
                gradientMode = "none";

                hideFrom = {
                  legend = false;
                  tooltip = false;
                  viz = false;
                };

                insertNulls = false;

                lineInterpolation = "linear";
                lineWidth = 1;
                pointSize = 5;

                scaleDistribution.type = "linear";

                showPoints = "auto";
                showValues = false;
                spanNulls = false;

                stacking = {
                  group = "A";
                  mode = "none";
                };

                thresholdsStyle.mode = "off";
              };

              mappings = [ ];

              thresholds = {
                mode = "absolute";
                steps = [
                  {
                    color = "green";
                    value = 0;
                  }
                  {
                    color = "red";
                    value = 80;
                  }
                ];
              };
            };

        overrides = [ ];
      };

      options =
        if datasourceType == "loki" then
          {
            dedupStrategy = "none";

            enableInfiniteScrolling = false;
            enableLogDetails = true;

            showControls = false;
            showTime = false;

            sortOrder = "Descending";
            wrapLogMessage = false;
          }
        else
          {
            legend = {
              inherit showLegend;

              calcs = [ ];
              displayMode = "list";
              placement = "bottom";
            };

            tooltip = {
              hideZeros = false;
              mode = "single";
              sort = "none";
            };
          };
    };

  dashboards = [ 
    "adguard"
    "immich"
    "lidarr"
    "slskd"
  ];

  dashboardFiles = builtins.listToAttrs (map (name: {
    name = "containers/grafana/provisioning/dashboards/${name}.json";
    value = {
      text = builtins.toJSON (import ./${name}.nix { inherit mkDashboard mkPanel; });
    };
  }) dashboards);
in
{
  home.file = dashboardFiles;
}
