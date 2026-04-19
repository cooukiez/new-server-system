/*
  modules/containers/services/media/music.nix

  part of der-home-server
  created 2026-04-19
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
  myServices = {
    lidarr = {
      serviceConfig = {
        description = "Music Tracker / Downloader";
        serviceType = "Restricted";

        subdomain = "lidarr";
        port = ports.lidarr;

        policy = "bypass";

        icon = "lidarr";
      };

      containerConfig = {
        files."config.xml" = {
          source = pkgs.writeText "config.xml" (mkLidarrXml lidarrSettings);
        };

        volumes = {
          lidarr-data = "/opt/lidarr/data";
        };
      };
    };

    slskd = {
      serviceConfig = {
        description = "Soulseek Network Integration";
        serviceType = "Restricted";

        subdomain = "slskd";
        port = ports.slskdHttp;

        policy = "bypass";

        icon = "slskd";
      };

      containerConfig = {
        files."slskd.yml" = {
          source = (pkgs.formats.yaml { }).generate "slskd.yml" slskdSettings;
        };

        volumes = {
          slskd-data = "/opt/slskd/data";
          slskd-download = "/media/download/slskd";
        };
      };
    };
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
        device = config.myServices.lidarr.containerConfig.volumes.lidarr-data;
      };

      volumes.slskd-download.volumeConfig = {
        type = "bind";
        device = "/media/download/slskd";
      };

      volumes.slskd-data.volumeConfig = {
        type = "bind";
        device = config.myServices.slskd.containerConfig.volumes.slskd-data;
      };

      containers.lidarr = {
        autoStart = true;

        unitConfig = {
          Requires = [ "postgres.service" ];
          After = [ "postgres.service" ];
        };

        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
          ExecStartPre = [
            "${pkgs.coreutils}/bin/cp ${
              config.myServices.lidarr.containerConfig.files."config.xml".fullPath
            } /opt/lidarr/data/config.xml"
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
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/usr/local/share/ca-certificates/ca.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # config
            "${volumes.lidarr-data.ref}:/config:U"

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
            "secrets/slskd/e_user"
            "secrets/slskd/e_pass"
            "secrets/slskd/e_webui-pw"
          ];

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/usr/local/share/ca-certificates/ca.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

            # config
            "${config.myServices.slskd.containerConfig.files."slskd.yml".fullPath}:/app/slskd.yml:ro"

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
