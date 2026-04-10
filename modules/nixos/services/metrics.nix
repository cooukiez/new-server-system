{
  ports,
  ...
}:
{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" "processes" "hwmon" ];
    port = ports.nodeExporter;
  };

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