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
let
  slskdSettingsFormat = pkgs.formats.yaml { };

  # lidarr settings
  lidarrVersion = "latest";

  # slskd settings
  slskdVersion = "latest";
  slskdSettings = {
    directories = {
      downloads = "/download/slskd";
      incomplete = "/download/slskd/incomplete";
    };

    shares = {
      directories = [ "/music" ];
    };

    web = {
      port = 5030;
      https = {
        disabled = true;
        port = 5031;
      };

      authentication = {
        disabled = false;
        username = "admin";
        apiKeys = {
          soularr = {
            key = "C2h1M5wh5iNUWNLYexHuTKj5s2mu29Xk";
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
in
{
  home.file."containers/slskd/slskd.yml" = {
    source = slskdSettingsFormat.generate "slskd.yml" slskdSettings;
  };

  age.secrets = {
    slskd-user.file = ../../../../secrets/slskd-user.age;
    slskd-pass.file = ../../../../secrets/slskd-pass.age;
    slskd-webui.file = ../../../../secrets/slskd-webui.age;
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
          networks = [ "container:gluetun" ];

          environmentFiles = [
            config.age.secrets.slskd-user.path
            config.age.secrets.slskd-pass.path
            config.age.secrets.slskd-webui.path
          ];

          environments = {
            SLSKD_REMOTE_CONFIGURATION = "false";
          };

          volumes = [
            # config
            "${config.home.homeDirectory}/containers/slskd/slskd.yml:/app/slskd.yml:ro"

            # volumes
            "${volumes.slskd-data.ref}:/app"

            "${volumes.media-download.ref}:/download"
            "${volumes.media-music.ref}:/music:ro"
          ];
        };
      };
    };
}
