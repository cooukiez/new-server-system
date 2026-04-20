/*
  modules/containers/services/vnstat.nix

  part of der-home-server
  created 2026-04-16
*/

{
  config,
  ports,
  ...
}:
let
  opengistVersion = "1";
in
{
  myServices.opengist = {
    serviceConfig = {
      name = "Opengist";
      description = "Unstructured Code Storage";
      serviceType = "Apps";

      subdomain = "gists";
      port = ports.opengistHttp;

      policy = "bypass";

      icon = "opengist";
    };

    containerConfig = {
      volumes = {
        opengist-data = "/opt/opengist/data";
      };
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.opengist-data.volumeConfig = {
        type = "bind";
        device = config.myServices.opengist.containerConfig.volumes.opengist-data;
      };

      containers.opengist = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/thomiceli/opengist:${opengistVersion}";
          name = "opengist";

          environments = {
            TZ = "Europe/Berlin";

            OG_DB_URI = "postgres://opengist:opengist@postgres:5432/opengist";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.opengist-data.ref}:/opengist:U"
          ];

          publishPorts = [
            "${toString ports.opengist}:2222/tcp"
            "${toString ports.opengistHttp}:6157/tcp"
          ];
        };
      };
    };
}
