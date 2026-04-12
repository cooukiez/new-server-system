/*
  modules/nixos/services/metrics.nix

  part of der-home-server
  created 2026-04-10
*/

{
  ports,
  ...
}:
{
  #
  # exporters
  #

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "systemd"
      "processes"
      "hwmon"
    ];
    port = ports.nodeExporter;
  };

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = ports.promtailExporter;
        grpc_listen_port = 0;
      };

      positions.filename = "/tmp/positions.yaml";
      clients = [ { url = "http://127.0.0.1:${toString ports.loki}/loki/api/v1/push"; } ];
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
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
            {
              source_labels = [ "__journal_syslog_identifier" ];
              target_label = "syslog_identifier";
            }
          ];
        }
      ];
    };
  };

  #
  # metrics
  #

  services.glances = {
    enable = true;

    extraArgs = [
      "-w"
      "-p"
      "${toString ports.glances}"
      "-B"
      "0.0.0.0"
    ];
  };
}
