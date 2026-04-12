/*
  modules/containers/services/immich.nix

  part of der-home-server
  created 2026-04-10
*/

{
  config,
  pkgs,
  ports,
  envSecretsPrefix,
  musicPath,
  ...
}:
let
  slskdSettingsFormat = pkgs.formats.yaml { };

  # lidarr settings
  lidarrVersion = "nightly";

  # slskd settings
  slskdVersion = "latest";
  slskdLidarrKey = "C2h1M5wh5iNUWNLYexHuTKj5s2mu29Xk";

  slskdSettings = {
    directories = {
      downloads = "/download/finished";
      incomplete = "/download/incomplete";
    };

    shares = {
      directories = [ "/music" ];
    };

    web = {
      port = 5030;
      https = {
        disabled = false;
        port = 5031;
      };

      authentication = {
        disabled = false;
        username = "admin";
        apiKeys = {
          lidarr = {
            key = slskdLidarrKey;
            cidr = "0.0.0.0/0,::/0";
          };
        };
      };
    };

    soulseek = {
      address = "vps.slsknet.org";
      port = 2271;
    };

    flags = {
      no_remote_configuration = true;
    };

    integration = {
      vpn = {
        enabled = true;
        portForwarding = false;
        pollingInterval = 2500;
        gluetun = {
          version = 1;
          url = "http://gluetun:8888";
          auth = "apikey";
          apiKey = "169qzBxFa0ET26rkTWa3akmVopysVilS";
        };
      };
    };
  };

  # deemix settings
  deemixVersion = "latest";
in
{
  home.file."containers/slskd/slskd.yml" = {
    source = slskdSettingsFormat.generate "slskd.yml" slskdSettings;
  };

  age.secrets = 
    let
      mkSecret = name: {
        file = ../../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
      };
    in
    {
      slskd-user  = mkSecret "slskd-user";
      slskd-pass  = mkSecret "slskd-pass";
      slskd-webui = mkSecret "slskd-webui";
    };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) volumes networks pods;
    in
    {
      volumes.lidarr-data.volumeConfig = {
        type = "bind";
        device = "/opt/lidarr/data";
      };

      volumes.slskd-data.volumeConfig = {
        type = "bind";
        device = "/opt/slskd/data";
      };

      volumes.slskd-download.volumeConfig = {
        type = "bind";
        device = "/media/download/slskd";
      };

      volumes.deemix-data.volumeConfig = {
        type = "bind";
        device = "/opt/deemix/data";
      };

      volumes.deemix-download.volumeConfig = {
        type = "bind";
        device = "/media/download/deemix";
      };

      containers.lidarr = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "lscr.io/linuxserver/lidarr:${lidarrVersion}";
          name = "lidarr";
          networks = [ "media-net" ];
          userns = "keep-id:uid=10000,gid=10000";
          
          environments = {
            PUID = "10000";
            PGID = "10000";
            TZ = "Europe/Berlin";
          };

          volumes = [
            "${volumes.lidarr-data.ref}:/config"
            
            # media volumes
            "${volumes.media-download.ref}:/download"
            "${volumes.media-music.ref}:/music"
          ];

          publishPorts = [
            "${toString ports.lidarr}:8686/tcp"
          ];
        };
      };

      containers.slskd = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/slskd/slskd:${slskdVersion}";
          name = "slskd";
          networks = [ "media-net" "vpn-service-net" ];
          userns = "keep-id:uid=10000,gid=10000";

          environmentFiles = [
            "secrets/slskd-user"
            "secrets/slskd-pass"
            "secrets/slskd-webui"
          ];

          environments = {
            SLSKD_REMOTE_CONFIGURATION = "false";
          };

          volumes = [
            # config
            "${config.home.homeDirectory}/containers/slskd/slskd.yml:/app/slskd.yml:ro"

            # volumes
            "${volumes.slskd-data.ref}:/app"

            "${volumes.slskd-download.ref}:/download"
            "${volumes.media-music.ref}:/music:ro"
          ];

          publishPorts = [
            "${toString ports.slskdHttp}:5030/tcp"
            "${toString ports.slskdHttps}:5031/tcp"
            "${toString ports.slskdPeer}:50300/tcp"
          ];
        };
      };

      containers.deemix = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "ghcr.io/bambanah/deemix:${deemixVersion}";
          name = "deemix";
          networks = [ "media-net"];
          userns = "keep-id:uid=10000,gid=10000";

          environments = {
            DEEMIX_SINGLE_USER = "true";

            DEEMIX_SERVER_PORT = "6595";
            DEEMIX_HOST = "0.0.0.0";

            DEEMIX_DATA_DIR = "/config";
            DEEMIX_MUSIC_DIR = "/downloads";
          };

          volumes = [
            "${volumes.deemix-data.ref}:/config:Z"
            "${volumes.deemix-download.ref}:/downloads:Z"
          ];

          publishPorts = [
            "${toString ports.deemix}:6595/tcp"
          ];
        };
      };
    };
}
