/*
modules/containers/services/media/transcoding.nix

part of server system
created 2026-06-14 by ludw
*/
{
  config,
  pkgs,
  images,
  ports,
  ...
}: {
  myServices.tdarr = {
    serviceConfig = {
      name = "Tdarr";
      description = "Transcoding Automation Platform";
      serviceType = "Restricted";

      subdomain = "tdarr";
      port = ports.tdarrWeb;

      policy = "two_factor";
      group = "admins";

      icon = "tdarr";
    };
  };

  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) volumes networks;
  in {
    volumes.tdarr-configs.volumeConfig = {
      type = "bind";
      device = "/opt/tdarr/configs";
    };

    volumes.tdarr-server.volumeConfig = {
      type = "bind";
      device = "/opt/tdarr/server";
    };

    volumes.tdarr-transcode-cache.volumeConfig = {
      type = "bind";
      device = "/opt/tdarr/transcode-cache";
    };

    volumes.tdarr-logs.volumeConfig = {
      type = "bind";
      device = "/opt/tdarr/logs";
    };

    containers.tdarr = {
      autoStart = true;

      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };

      containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.pullImage images.tdarr}";
        name = "tdarr";
        networks = [networks.media-net.ref];

        environments = {
          TZ = "Europe/Berlin";

          PUID = "0";
          GUID = "0";

          serverIP = "0.0.0.0";
          serverPort = "8266";
          webUIPort = "8265";

          internalNode = "true";
          inContainer = "true";

          ffmpegVersion = "7";

          nodeName = "Internal";

          auth = "false";
          openBrowser = "true";

          maxLogSizeMB = "10";

          cronPluginUpdate = "";
        };

        volumes = [
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"

          # certificates
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/certs/ca.crt:/certs/ca.crt:ro"

          "${volumes.tdarr-configs.ref}:/app/configs:U"
          "${volumes.tdarr-server.ref}:/app/server:U"
          "${volumes.tdarr-transcode-cache.ref}:/temp:U"
          "${volumes.tdarr-logs.ref}:/app/logs:U"

          "${volumes.media-music.ref}:/media/music"
        ];

        publishPorts = [
          "${toString ports.tdarrWeb}:8265"
          "${toString ports.tdarr}:8266"
        ];
      };
    };
  };
}
