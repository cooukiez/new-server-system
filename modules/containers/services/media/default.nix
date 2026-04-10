/*
  modules/containers/services/immich.nix

  part of der-home-server
  created 2026-04-10
*/

{
  config,
  ports,
  ...
}:
let
  musicPath = "/media/music";
in
{
  imports = [
    ./music.nix
  ];

  _module.args = {
    musicPath;
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      networks.media-net = {
        networkConfig = {
          internal = false;
        };
      };

      volumes.media-music.volumeConfig = {
        type = "bind";
        device = musicPath;
      };
    };
}
