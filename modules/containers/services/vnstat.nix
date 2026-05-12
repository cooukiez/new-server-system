/*
  modules/containers/services/vnstat.nix

  part of server system
  created 2026-04-16
*/

{
  config,
  pkgs,
  images,
  ports,
  ...
}:
{
  myServices.vnstat = {
    serviceConfig = {
      name = "VNStat Dashboard";
      description = "View Network Statistics";
      serviceType = "Monitoring";

      subdomain = "vnstat";
      port = ports.vnstat;

      policy = "two_factor";
      group = "admins";

      icon = "mdi-chart-timeline-variant";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      # vnstat database
      volumes.vnstat-db.volumeConfig = {
        type = "bind";
        device = "/var/lib/vnstat";
      };

      containers.vnstat-dashboard = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.vnstat-dashboard}";
          name = "vnstat-dashboard";

          environments = {
            TZ = "Europe/Berlin";

            PORT = "80";
            ALLOWED_PREFIXES = "enp";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.vnstat-db.ref}:/var/lib/vnstat:ro"
          ];

          publishPorts = [
            "${toString ports.vnstat}:80/tcp"
          ];
        };
      };
    };
}
