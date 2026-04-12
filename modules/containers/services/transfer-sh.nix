/*
  modules/containers/services/qbittorrent.nix

  part of der-home-server
  created 2026-04-12
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
          image = "docker.io/dutchcoders/transfer.sh:${transferSHVersion}";
          name = "transfer-sh";

          exec = [
            "--provider" "local"
            "--basedir" "/data"
          ];

          environments = {
            TZ = "Europe/Berlin";
          };

          volumes = [
            "${volumes.transfer-sh-data.ref}:/data"
          ];

          publishPorts = [
            "${toString ports.transferSH}:8080/tcp"
          ];
        };
      };
    };
}
