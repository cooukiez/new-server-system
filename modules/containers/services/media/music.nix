/*
  modules/containers/services/media/music.nix

  part of der-home-server
  created 2026-04-14
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

  mkLidarrXml = attrs: ''
    <Config>
      ${builtins.concatStringsSep "\n  " (
        pkgs.lib.mapAttrsToList (k: v: "<${k}>${toString v}</${k}>") attrs
      )}
    </Config>
  '';

  lidarrVersion = "nightly";
  lidarrListsNginxVersion = "alpine";
  slskdVersion = "latest";

  # lidarr settings
  lidarrSettings = {
    InstanceName = "Lidarr";

    BindAddress = "*";
    Port = "8686";
    SslPort = "6868";

    UrlBase = "";

    EnableSsl = "False";
    SslCertPath = "";
    SslCertPassword = "";

    LaunchBrowser = "True";
    ApiKey = "d854c071ad1b4b47ba6afca9a10e5049";

    AuthenticationMethod = "Forms";
    AuthenticationRequired = "Enabled";

    Branch = "nightly";
    UpdateMechanism = "Docker";

    # postgres configuration
    PostgresUser = "lidarr";
    PostgresPassword = "lidarr";

    PostgresHost = "host.containers.internal";
    PostgresPort = "${toString ports.postgres}";

    PostgresMainDb = "lidarr-main";
    PostgresLogDb = "lidarr-log";

    LogLevel = "debug";
    AnalyticsEnabled = "False";
  };

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
  home.file."containers/lidarr/config.xml" = {
    text = mkLidarrXml lidarrSettings;
  };

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
      slskd-user = mkSecret "slskd/e_user";
      slskd-pass = mkSecret "slskd/e_pass";
      slskd-webui = mkSecret "slskd/e_webui-pw";
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

        unitConfig = {
          # requires database
          Requires = [ "postgres.service" ];
          After = [ "postgres.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
          ExecStartPre = [
            "${pkgs.coreutils}/bin/cp ${config.home.homeDirectory}/containers/lidarr/config.xml /opt/lidarr/data/config.xml"
            "${pkgs.coreutils}/bin/chmod 644 /opt/lidarr/data/config.xml"
          ];
        };

        containerConfig = {
          image = "lscr.io/linuxserver/lidarr:${lidarrVersion}";
          name = "lidarr";
          userns = "keep-id:uid=10000,gid=10000";
          networks = [ "media-net" ];

          environments = {
            TZ = "Europe/Berlin";

            PUID = "10000";
            GUID = "10000";
          };

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            # config
            "${volumes.lidarr-data.ref}:/config:ro,U"

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
          image = "quay.io/nginx:${lidarrListsNginxVersion}";
          name = "lidarr-lists";
          networks = [ "media-net" ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

            # config
            "${config.home.homeDirectory}/containers/lidarr/lidarr-lists.conf:/etc/nginx/conf.d/default.conf:ro,U"

            # volumes
            "${volumes.lidarr-lists.ref}:/lists:ro,U"
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

            environments = {
              TZ = "Europe/Berlin";

              LIDARR_URL = "http://lidarr:8686";
            };

            volumes = [
              "/etc/timezone:/etc/timezone:ro"
              "/etc/localtime:/etc/localtime:ro"

              # certificates
              "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
              "/certs/home.lan.crt:/certs/home.lan.crt:ro"

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

        unitConfig = {
          Requires = [ "gluetun.service" ];
          After = [ "gluetun.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };

        containerConfig = {
          image = "docker.io/slskd/slskd:${slskdVersion}";
          name = "slskd";
          userns = "keep-id:uid=10000,gid=10000";
          user = "10000:10000";

          networks = [
            "media-net"
            "vpn-service-net"
          ];

          environments = {
            TZ = "Europe/Berlin";

            SLSKD_REMOTE_CONFIGURATION = "false";
          };

          environmentFiles = [
            "secrets/slskd/user"
            "secrets/slskd/password"
            "secrets/slskd/webui-pw"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/certs/home.lan.crt:/usr/local/share/ca-certificates/home.lan.crt:ro"
            "/certs/home.lan.crt:/certs/home.lan.crt:ro"

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
