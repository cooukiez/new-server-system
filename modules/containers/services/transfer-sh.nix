/*
  modules/containers/services/transfer-sh.nix

  part of der-home-server
  created 2026-04-14
*/

{
  config,
  ports,
  ...
}:
let
  transferSHVersion = "latest-noroot";
in
{
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
          image = "quay.io/transfer.sh:${transferSHVersion}";
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
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            "${volumes.transfer-sh-data.ref}:/data:U"
          ];

          publishPorts = [
            "${toString ports.transferSH}:8080/tcp"
          ];
        };
      };
    };
}
