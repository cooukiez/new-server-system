/*
  modules/containers/services/immich.nix

  part of der-home-server
  created 2026-04-10
*/

{
  config,
  ports,
  musicPath,
  ...
}:
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.lidarr-data.volumeConfig = {
        type = "bind";
        device = "/opt/lidarr/data";
      };
    };
}
