/*
  modules/containers/services/vnstat.nix

  part of der-home-server
  created 2026-04-12
*/

{
  config,
  ports,
  ...
}:
let
  vnstatDashboardVersion = "latest";
in
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      # vnstat database volume
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
          image = "docker.io/kshitizb/vnstat-dashboard:${vnstatDashboardVersion}";
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
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            "${volumes.vnstat-db.ref}:/var/lib/vnstat:ro"
          ];

          publishPorts = [
            "${toString ports.vnstat}:80/tcp"
          ];
        };
      };
    };
}
