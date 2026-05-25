/*
modules/containers/services/media/default.nix

part of server system
created 2026-04-16
*/
{
  config,
  pkgs,
  images,
  ports,
  musicPath,
  downloadPath,
  ...
}:
# todo: ldap ssl
{
  imports = [
    ./music.nix
    ./qbittorrent.nix
  ];

  myServices.jellyfin = {
    serviceConfig = {
      name = "Jellyfin";
      description = "Universal Media Serve";
      serviceType = "Apps";

      subdomain = "jellyfin";
      port = ports.jellyfin;

      policy = "bypass";

      icon = "jellyfin";
    };
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks pods;
  in {
    networks.media-net = {
      networkConfig = {
        internal = false;
      };
    };

    # general volumes
    volumes.media-music.volumeConfig = {
      type = "bind";
      device = musicPath;
    };

    volumes.media-download.volumeConfig = {
      type = "bind";
      device = downloadPath;
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
        image = "docker-archive:${pkgs.dockerTools.pullImage images.jellyfin}";
        name = "jellyfin";
        networks = ["media-net"];

        addHosts = [
          "ldap.home.lan:host-gateway"
        ];

        environments = {
          TZ = "Europe/Berlin";

          JELLYFIN_CONFIG_DIR = "/config";
          JELLYFIN_DATA_DIR = "/data";
          JELLYFIN_CACHE_DIR = "/cache";
          JELLYFIN_LOG_DIR = "/log";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          # volumes
          "${volumes.jellyfin-config.ref}:/config:U"
          "${volumes.jellyfin-data.ref}:/data:U"
          "${volumes.jellyfin-cache.ref}:/cache:U"
          "${volumes.jellyfin-log.ref}:/log:U"

          "${volumes.media-music.ref}:/media/music:ro"
        ];

        publishPorts = [
          "${toString ports.jellyfin}:8096/tcp"
        ];

        healthStartPeriod = "60s";
        healthInterval = "30s";
      };
    };
  };
}
