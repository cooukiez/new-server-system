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
  downloadPath = "/media/download";
  musicPath = "/media/music";

  jellyfinVersion = "latest";
in
{
  imports = [
    ./music.nix
  ];

  _module.args = {
    musicPath = musicPath;
  };

  home.file."containers/jellyfin/root.crt".source = ../../../../home.lan.crt;

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

      # general volumes
      volumes.media-download.volumeConfig = {
        type = "bind";
        device = downloadPath;
      };

      volumes.media-music.volumeConfig = {
        type = "bind";
        device = musicPath;
      };

      # jellyfin volumes
      volumes.jellyfin-config.volumeConfig = {
        type = "bind";
        device = "/opt/jellyfin/config";
      };
      
      volumes.jellyfin-data.volumeConfig = {
        type = "bind";
        device = "/opt/jellyfin/data";
      };

      volumes.jellyfin-cache.volumeConfig = {
        type = "bind";
        device = "/opt/jellyfin/cache";
      };

      volumes.jellyfin-log.volumeConfig = {
        type = "bind";
        device = "/opt/jellyfin/log";
      };

      containers.jellyfin = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/jellyfin/jellyfin:${jellyfinVersion}";
          name = "jellyfin";
          networks = [ "media-net" ];

          addHosts = [
            "auth.home.lan:host-gateway"
          ];

          exec = "/bin/bash -c 'update-ca-certificates && exec /jellyfin/jellyfin'";

          environments = {
            JELLYFIN_CONFIG_DIR = "/jellyfin/config";
            JELLYFIN_DATA_DIR = "/jellyfin/data";
            JELLYFIN_CACHE_DIR = "/jellyfin/cache";
            JELLYFIN_LOG_DIR = "/jellyfin/log";
          };

          volumes = [
            # secrets
            "${config.home.homeDirectory}/containers/jellyfin/root.crt:/usr/local/share/ca-certificates/root.crt:ro"

            # volumes
            "${volumes.jellyfin-config.ref}:/jellyfin/config"
            "${volumes.jellyfin-data.ref}:/jellyfin/data"
            "${volumes.jellyfin-cache.ref}:/jellyfin/cache"
            "${volumes.jellyfin-log.ref}:/jellyfin/log"
            
            "${volumes.media-music.ref}:/media/music:ro"
          ];

          publishPorts = [
            "${toString ports.jellyfin}:8096/tcp"
          ];
        };
      };
    };
}
