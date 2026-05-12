/*
  modules/containers/services/media/music.nix

  part of der-home-server
  created 2026-04-19
*/

{
  config,
  pkgs,
  images,
  ports,
  mkConf,
  envSecretsPrefix,
  mkEnv,
  musicPath,
  downloadPath,
  ...
}:
let
  mkLidarrXml = attrs: ''
    <Config>
      ${builtins.concatStringsSep "\n  " (
        pkgs.lib.mapAttrsToList (k: v: "<${k}>${toString v}</${k}>") attrs
      )}
    </Config>
  '';

  # lidarr settings
  createLidarrConf = mkConf {
    path = "containers/lidarr/config.xml";
    source = pkgs.writeText "lidarr-settings" (mkLidarrXml {
      InstanceName = "Lidarr";

      BindAddress = "*";
      Port = "8686";
      SslPort = "6868";

      UrlBase = "";

      EnableSsl = "False";
      SslCertPath = "";
      SslCertPassword = "";

      LaunchBrowser = "True";
      ApiKey = "@PLACEHOLDER_API_KEY@";

      AuthenticationMethod = "Forms";
      AuthenticationRequired = "Enabled";

      Branch = "nightly";
      UpdateMechanism = "Docker";

      # postgres configuration
      PostgresUser = "lidarr";
      PostgresPassword = "@PLACEHOLDER_DB_PASS@";

      PostgresHost = "host.containers.internal";
      PostgresPort = "${toString ports.postgres}";

      PostgresMainDb = "lidarr-main";
      PostgresLogDb = "lidarr-log";

      LogLevel = "debug";
      AnalyticsEnabled = "False";
    });

    secrets = {
      "PLACEHOLDER_API_KEY" = config.age.secrets.lidarr-api-key.path;

      # "PLACEHOLDER_DB_PASS" = config.age.secrets.lidarr-db-pass.path;
      "PLACEHOLDER_DB_PASS" = pkgs.writeText "db-pass" "lidarr";
    };
  };

  # slskd settings
  createSlskdConf = mkConf {
    path = "containers/slskd/slskd.yml";
    source = (pkgs.formats.yaml { }).generate "slskd-settings" {
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
          password = "@PLACEHOLDER_WEBUI_PASS@";

          apiKeys = {
            lidarr = {
              key = "@PLACEHOLDER_LIDARR_API_KEY@";
              cidr = "0.0.0.0/0,::/0";
            };
          };
        };
      };

      soulseek = {
        address = "vps.slsknet.org";
        port = 2271;

        username = "@PLACEHOLDER_USER@";
        password = "@PLACEHOLDER_PASS@";
      };

      flags = {
        no_remote_configuration = true;
      };

      integrations = {
        vpn = {
          enabled = true;
          portForwarding = false;
          pollingInterval = 2500;
          gluetun = {
            version = 1;
            url = "http://gluetun:8888";
            auth = "apikey";
            apiKey = "@PLACEHOLDER_GLUETUN_API_KEY@";
          };
        };
      };
    };

    secrets = {
      "PLACEHOLDER_GLUETUN_API_KEY" = config.age.secrets.slskd-gluetun-api-key.path;
      "PLACEHOLDER_LIDARR_API_KEY" = config.age.secrets.slskd-lidarr-api-key.path;
      "PLACEHOLDER_USER" = config.age.secrets.slskd-user.path;
      "PLACEHOLDER_PASS" = config.age.secrets.slskd-pass.path;
      "PLACEHOLDER_WEBUI_PASS" = config.age.secrets.slskd-webui-pass.path;
    };
  };
in
{
  myServices = {
    lidarr = {
      serviceConfig = {
        name = "Lidarr";
        description = "Music Tracker / Downloader";
        serviceType = "Restricted";

        subdomain = "lidarr";
        port = ports.lidarr;

        policy = "bypass";

        icon = "lidarr";
      };
    };

    slskd = {
      serviceConfig = {
        name = "Slskd";
        description = "Soulseek Network Integration";
        serviceType = "Restricted";

        subdomain = "slskd";
        port = ports.slskdHttp;

        policy = "bypass";

        icon = "slskd";
      };
    };
  };

  age.secrets =
    let
      mkSecret = name: {
        file = ../../../../secrets/${name}.age;
      };
    in
    {
      lidarr-api-key = mkSecret "containers/lidarr/s_api-key";
      lidarr-db-pass = mkSecret "containers/lidarr/s_db-pass";

      slskd-gluetun-api-key = mkSecret "containers/gluetun/s_api-key";
      slskd-lidarr-api-key = mkSecret "containers/slskd/s_lidarr-api-key";
      slskd-user = mkSecret "containers/slskd/s_user";
      slskd-pass = mkSecret "containers/slskd/s_pass";
      slskd-webui-pass = mkSecret "containers/slskd/s_webui-pass";
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

      volumes.lidarr-cache.volumeConfig = {
        type = "bind";
        device = "/opt/lidarr/cache";
      };

      volumes.slskd-download.volumeConfig = {
        type = "bind";
        device = "${downloadPath}/slskd";
      };

      volumes.slskd-data.volumeConfig = {
        type = "bind";
        device = "/opt/slskd/data";
      };

      # todo: bring deemix back
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
            "+${pkgs.writeShellScript "pre-lidarr" ''
              ${createLidarrConf}

              # deezer download
              ${pkgs.coreutils}/bin/mkdir -p "${downloadPath}/deezer"
              # spotify playlist cache
              ${pkgs.coreutils}/bin/mkdir -p "/opt/lidarr/cache/spotify"

              ${pkgs.coreutils}/bin/cp ${config.home.homeDirectory}/containers/lidarr/config.xml /opt/lidarr/data/config.xml
              ${pkgs.coreutils}/bin/chmod 644 /opt/lidarr/data/config.xml
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.lidarr}";
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
            "/certs/ca.crt:/certs/ca.crt:ro"

            # volumes
            "${volumes.lidarr-data.ref}:/config:U"
            "${volumes.lidarr-cache.ref}:/cache:U"

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

          ExecStartPre = [
            "+${pkgs.writeShellScript "pre-slskd" ''
              ${createSlskdConf}

              ${pkgs.coreutils}/bin/mkdir -p "${downloadPath}/slskd/finished"
              ${pkgs.coreutils}/bin/mkdir -p "${downloadPath}/slskd/incomplete"
            ''}"
          ];
        };

        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.pullImage images.slskd}";
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

          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"

            # certificates
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/certs/ca.crt:/certs/ca.crt:ro"

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
