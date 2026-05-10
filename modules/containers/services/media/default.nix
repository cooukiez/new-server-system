/*
  modules/containers/services/media/default.nix

  part of der-home-server
  created 2026-04-16
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
    ./qbittorrent.nix
  ];

  _module.args = {
    musicPath = musicPath;
  };

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

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-start" ''
              ${pkgs.coreutils}/bin/mkdir -p "/opt/jellyfin/config"
              ${pkgs.coreutils}/bin/mkdir -p "/opt/jellyfin/data"
              ${pkgs.coreutils}/bin/mkdir -p "/opt/jellyfin/cache"
              ${pkgs.coreutils}/bin/mkdir -p "/opt/jellyfin/log"
            ''}"
          ];
        };

        containerConfig = {
          image = "docker.io/jellyfin/jellyfin:${jellyfinVersion}";
          name = "jellyfin";
          networks = [ "media-net" ];

          addHosts = [
            "ldap.home.lan:host-gateway"
          ];

          environments = {
            TZ = "Europe/Berlin";

            JELLYFIN_CONFIG_DIR = "/jellyfin/config";
            JELLYFIN_DATA_DIR = "/jellyfin/data";
            JELLYFIN_CACHE_DIR = "/jellyfin/cache";
            JELLYFIN_LOG_DIR = "/jellyfin/log";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # volumes
            "${volumes.jellyfin-config.ref}:/jellyfin/config:U"
            "${volumes.jellyfin-data.ref}:/jellyfin/data:U"
            "${volumes.jellyfin-cache.ref}:/jellyfin/cache:U"
            "${volumes.jellyfin-log.ref}:/jellyfin/log:U"

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
