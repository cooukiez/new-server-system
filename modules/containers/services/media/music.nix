/*
  modules/containers/services/media/music.nix

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

  lidarrVersion = "nightly";
  lidarrListsNginxVersion = "alpine";
  slskdVersion = "latest";

  # slskd settings
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
in
{
  home.file."containers/slskd/slskd.yml" = {
    source = slskdSettingsFormat.generate "slskd.yml" slskdSettings;
  };

  home.file."containers/lidarr/lidarr-lists.conf" = {
    text = ''
      server {
        listen 80;
        server_name localhost;

        location / {
          root /lists;
          autoindex on;
          autoindex_exact_size off;
          autoindex_localtime on;
          default_type application/json;
        }
      }
    '';
  };


  age.secrets =
    let
      mkSecret = name: {
        file = ../../../../secrets/${name}.age;
        path = "${envSecretsPrefix}/${name}";
      };
    in
    {
      slskd-user = mkSecret "slskd/user";
      slskd-pass = mkSecret "slskd/password";
      slskd-webui = mkSecret "slskd/webui-pw";
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

      volumes.lidarr-lists.volumeConfig = {
        type = "bind";
        device = "/opt/lidarr/lists";
      };

      volumes.cmdarr-data.volumeConfig = {
        type = "bind";
        device = "/opt/cmdarr/data";
      };

      volumes.slskd-data.volumeConfig = {
        type = "bind";
        device = "/opt/slskd/data";
      };

      volumes.slskd-download.volumeConfig = {
        type = "bind";
        device = "/media/download/slskd";
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

      containers.lidarr-lists = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/nginx:${lidarrListsNginxVersion}";
          name = "lidarr-lists";
          networks = [ "media-net" ];

          volumes = [
            "${config.home.homeDirectory}/containers/lidarr/lidarr-lists.conf:/etc/nginx/conf.d/default.conf:ro"

            "${volumes.lidarr-lists.ref}:/lists:ro"
          ];

          publishPorts = [
            "${toString ports.lidarrLists}:80/tcp"
          ];
        };
      };

      /*
      containers.cmdarr = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/nginx:${lidarrListsNginxVersion}";
          name = "cmdarr";
          networks = [ "media-net" ];
          userns = "keep-id:uid=10000,gid=10000";

          environments = {
            PUID = "10000";
            PGID = "10000";
            TZ = "Europe/Berlin";

            LIDARR_URL = "http://lidarr:8686";
          };
          
          volumes = [
            "${volumes.cmdarr-data.ref}:/app/data:ro"
          ];

          publishPorts = [
            "${toString ports.cmdarr}:8080/tcp"
          ];
        };
      };
      */

      containers.slskd = {
        autoStart = true;
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/slskd/slskd:${slskdVersion}";
          name = "slskd";
          networks = [
            "media-net"
            "vpn-service-net"
          ];
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
    };
}
