/*
  modules/containers/services/transfer-sh.nix

  part of server system
  created 2026-04-14
*/
{
  config,
  pkgs,
  images,
  ports,
  ...
}:
{
  myServices.transfer-sh = {
    serviceConfig = {
      name = "transfer.sh";
      description = "Convenient File Transfer";
      serviceType = "Apps";

      subdomain = "transfer";
      port = ports.transferSH;

      policy = "bypass";

      icon = "https://avatars.githubusercontent.com/u/5444419?s=48&v=4";
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.transfer-sh-data.volumeConfig = {
        type = "bind";
        device = "/opt/transfer-sh/data";
      };

      containers.transfer-sh = {
        autoStart = true;

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.transfer-sh}";
          name = "transfer-sh";

          exec = [
            "--provider"
            "local"
            "--basedir"
            "/data"
          ];

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            "${volumes.transfer-sh-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.transferSH}:8080/tcp"
          ];
        };
      };
    };
}
