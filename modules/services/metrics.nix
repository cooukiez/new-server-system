/*
  modules/nixos/services/metrics.nix

  part of der-home-server
  created 2026-04-17
*/

{
  config,
  lib,
  hostConfig,
  ...
}:
let
  cfg = config.networkConfig;

  mkEnableDefault = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
in
{
  options.networkConfig = {
    prometheus = mkEnableDefault;
    promtail = mkEnableDefault;
  };

  config = {
    services.prometheus.exporters.node = lib.mkIf cfg.prometheus {
      enable = true;
      enabledCollectors = [
        "systemd"
        "processes"
        "hwmon"
      ];

      port = hostConfig.ports.nodeExporter;
    };

    services.promtail = lib.mkIf cfg.promtail {
      enable = true;
      configuration = {
        positions.filename = "/tmp/positions.yaml";

        server = {
          http_listen_port = hostConfig.ports.promtailExporter;
          grpc_listen_port = 0;
        };

        clients = [
          {
            url = "http://127.0.0.1:${toString hostConfig.ports.loki}/loki/api/v1/push";
          }
        ];

        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";

              labels = {
                job = "systemd-journal";
                host = "dhs";
              };
            };

            relabel_configs = [
              {
                source_labels = [
                  "__journal__systemd_unit"
                ];

                target_label = "unit";
              }
              {
                source_labels = [
                  "__journal_syslog_identifier"
                ];

                target_label = "syslog_identifier";
              }
            ];
          }
        ];
      };
    };
  };
}
