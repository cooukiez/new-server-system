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
  mkLidarrXml = attrs: ''
    <Config>
      ${builtins.concatStringsSep "\n  " (
        pkgs.lib.mapAttrsToList (k: v: "<${k}>${toString v}</${k}>") attrs
      )}
    </Config>
  '';

  lidarrVersion = "nightly";
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

    # todo: private db password

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

  # todo: private api key
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

    integrations = {
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

  home.file."containers/lidarr/config.xml".source = pkgs.writeText "config.xml" (
    mkLidarrXml lidarrSettings
  );

  home.file."containers/slskd/slskd.yml".source =
    (pkgs.formats.yaml { }).generate "slskd.yml"
      slskdSettings;

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

      volumes.lidarr-cache.volumeConfig = {
        type = "bind";
        device = "/opt/lidarr/cache";
      };

      volumes.slskd-download.volumeConfig = {
        type = "bind";
        device = "/media/download/slskd";
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
              ${pkgs.coreutils}/bin/mkdir -p "/opt/lidarr/data"
              ${pkgs.coreutils}/bin/mkdir -p "/opt/lidarr/cache/spotify"

              ${pkgs.coreutils}/bin/cp ${config.home.homeDirectory}/containers/lidarr/config.xml /opt/lidarr/data/config.xml
              ${pkgs.coreutils}/bin/chmod 644 /opt/lidarr/data/config.xml
            ''}"
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
              ${pkgs.coreutils}/bin/mkdir -p "/opt/slskd/data"
            ''}"
          ];
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

          labels = {
            "io.containers.autoupdate" = "registry";
          };

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
